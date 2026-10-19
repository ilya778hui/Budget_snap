const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");
const https = require("https");

// ===== ФУНКЦИЯ 1: AI Чат =====
exports.askAI = onCall(async (request) => {
  logger.info("askAI called, auth:", request.auth ? request.auth.uid : "NO AUTH");

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Требуется авторизация");
  }

  const apiKey = process.env.ANTHROPIC_KEY;
  logger.info("API key exists:", !!apiKey);

  const messages = request.data.messages;
  logger.info("Messages:", JSON.stringify(messages));

  const body = JSON.stringify({
    model: "claude-sonnet-4-5",
    max_tokens: 1024,
    system: "Ты — персональный финансовый помощник. Отвечай кратко на языке пользователя.",
    messages: messages,
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: "api.anthropic.com",
        path: "/v1/messages",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
          "Content-Length": Buffer.byteLength(body),
        },
      },
      (res) => {
        let responseData = "";
        res.on("data", (chunk) => { responseData += chunk; });
        res.on("end", () => {
          logger.info("Anthropic response status:", res.statusCode);
          logger.info("Anthropic response:", responseData);
          try {
            const parsed = JSON.parse(responseData);
            if (parsed.error) {
              reject(new HttpsError("internal", parsed.error.message));
            } else {
              resolve({ reply: parsed.content[0].text });
            }
          } catch (e) {
            reject(new HttpsError("internal", "Parse error: " + e.message));
          }
        });
      }
    );
    req.on("error", (e) => {
      logger.error("Request error:", e);
      reject(new HttpsError("internal", e.message));
    });
    req.write(body);
    req.end();
  });
});

// ===== ФУНКЦИЯ 2: Генерация квиза =====
exports.generateQuiz = onCall(async (request) => {
  logger.info("generateQuiz called, auth:", request.auth ? request.auth.uid : "NO AUTH");

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Требуется авторизация");
  }

  const apiKey = process.env.ANTHROPIC_KEY;
  const difficulty = request.data.difficulty || "средний";

  logger.info("Generating quiz, difficulty:", difficulty);

  const prompt = `Создай 10 вопросов для теста по финансовой грамотности.
Уровень сложности: ${difficulty}.

Верни ТОЛЬКО валидный JSON массив без markdown, без пояснений, без \`\`\`json:
[
  {
    "question": "текст вопроса",
    "options": ["вариант A", "вариант B", "вариант C", "вариант D"],
    "correct": "правильный вариант (точно как в options)",
    "explanation": "краткое объяснение почему этот ответ правильный"
  }
]`;

  const body = JSON.stringify({
    model: "claude-sonnet-4-5",
    max_tokens: 4000,
    messages: [{ role: "user", content: prompt }],
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: "api.anthropic.com",
        path: "/v1/messages",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
          "Content-Length": Buffer.byteLength(body),
        },
      },
      (res) => {
        let responseData = "";
        res.on("data", (chunk) => { responseData += chunk; });
        res.on("end", () => {
          logger.info("Anthropic quiz response status:", res.statusCode);
          try {
            const parsed = JSON.parse(responseData);
            if (parsed.error) {
              reject(new HttpsError("internal", parsed.error.message));
              return;
            }
            const text = parsed.content[0].text.trim();
            const questions = JSON.parse(text);
            logger.info("Generated questions count:", questions.length);
            resolve({ questions });
          } catch (e) {
            logger.error("Parse error:", e);
            reject(new HttpsError("internal", "Parse error: " + e.message));
          }
        });
      }
    );
    req.on("error", (e) => {
      logger.error("Request error:", e);
      reject(new HttpsError("internal", e.message));
    });
    req.write(body);
    req.end();
  });
});