// morphed-backend/src/openrouterClient.js

import { OpenRouter } from "@openrouter/sdk";

const DEFAULT_MODEL = "qwen/qwen-2.5-vl-7b-instruct:free";

const PRESENCE_PROMPT = `
You are a strict validator for a profile-photo pipeline. Decide PASS or FAIL.
Be conservative: if anything is unclear, return FAIL.

PASS only if ALL are true:
1) Exactly one real human is present (not a drawing, statue, mannequin, doll, toy, animal, plant, object, or AI art).
2) A face is clearly visible, not heavily occluded, and not cropped off (eyes, nose, and mouth all visible).
3) Face size is reasonable: roughly 8%–45% of the image area, and the face is not touching the image edges.
4) Pose is usable: not extreme yaw or roll, no severe motion blur.
5) Lighting is adequate: not too dark or overexposed to see facial features.

FAIL if any of the above is false, or if there are multiple people, partial faces, or non-human subjects.

Return ONLY JSON with keys:
pass (boolean),
blockingMessage (string or null),
warnings (array of strings),
debug (string).
If FAIL, set blockingMessage to exactly:
"Please upload a clear photo of a single person with a visible face."
If PASS, include warnings ONLY when the issue is very obvious and likely to make results unusable.
Be extremely conservative with warnings. Do NOT warn for mild or moderate issues.
Warnings should be short suggestions like:
"Blurry — a sharper photo may improve results."
"Low light — a brighter photo may improve results."
"Face is small in frame — a closer photo may improve results."
"Strong angle — a straighter, front-facing photo may improve results."
`.trim();

const FACE_PROMPT = `
You are a validator for a face-focused editing pipeline. Decide PASS or FAIL.
Be conservative ONLY about face visibility and quality. Ignore shoulders and body framing.

PASS only if ALL are true:
1) Exactly one real human is present (not a drawing, statue, mannequin, doll, toy, animal, plant, object, or AI art).
2) A face is clearly visible with eyes, nose, and mouth mostly visible (minor occlusions OK).
3) The face is usable: not extremely blurry, not too dark/overexposed to see facial features.
4) Pose is usable: no extreme yaw or roll that hides major facial features.

DO NOT require shoulders or full upper body. Tight face crops are OK.
Face may be close to edges if features are still visible.

FAIL if any of the above is false, or if there are multiple people, partial faces, or non-human subjects.

Return ONLY JSON with keys:
pass (boolean),
blockingMessage (string or null),
warnings (array of strings),
debug (string).
If FAIL, set blockingMessage to exactly:
"Please upload a clear photo of a single person with a visible face."
If PASS, include warnings ONLY for severe-but-usable issues (very blurry, very low light, or face extremely small but still visible).
Do NOT warn about angle or mild/moderate issues. If unsure, PASS with no warnings.
Warnings should be short suggestions like:
"Blurry — a sharper photo may improve results."
"Low light — a brighter photo may improve results."
"Face is small in frame — a closer photo may improve results."
`.trim();

const PHYSIQUE_PROMPT = `
You are a validator for a physique-focused editing pipeline. Decide PASS or FAIL.
Be conservative ONLY about subject presence, visibility of the target body region, and severe image issues.
Do NOT require a face. Shirtless, shorts, and legs-only shots are acceptable.

PASS only if ALL are true:
1) Exactly one real human is present (not a drawing, statue, mannequin, doll, toy, animal, plant, object, or AI art).
2) The intended body region is clearly visible (torso or legs). Partial body is OK if the target region is visible.
3) The image is usable: not extremely blurry, and not so dark/overexposed that the body region is unreadable.

DO NOT require full body or shoulders. Mirror selfies are OK. Tight crops are OK if the target region is clear.

FAIL if any of the above is false, or if there are multiple people, non-human subjects, or the target region is fully missing/obscured.

Return ONLY JSON with keys:
pass (boolean),
blockingMessage (string or null),
warnings (array of strings),
debug (string).
If FAIL, set blockingMessage to exactly:
"Please upload a clear photo of a single person with a visible body."
If PASS, include warnings ONLY for severe-but-usable issues (very blurry, very low light, strong backlight, or target region partially occluded).
Do NOT warn for mild/moderate issues. If unsure, PASS with no warnings.
Warnings should be short suggestions like:
"Blurry — a sharper photo may improve results."
"Low light — a brighter photo may improve results."
"Strong backlight — softer lighting may improve results."
"Target area partially occluded — clearer framing may improve results."
`.trim();

function buildPrompt(mode) {
    if (mode === "face") return FACE_PROMPT;
    if (mode === "physique") return PHYSIQUE_PROMPT;
    return PRESENCE_PROMPT;
}

export async function checkPresenceWithOpenRouter(imageBase64, mimeType, apiKey, models, baseUrl, mode) {
    if (!apiKey) {
        throw new Error("OPENROUTER_API_KEY is not set");
    }

    const dataUrl = `data:${mimeType};base64,${imageBase64}`;
    const openRouter = createClient(apiKey, baseUrl);
    const prompt = buildPrompt(mode);

    const modelList = normalizeModels(models);
    let lastError = null;

    for (const modelId of modelList) {
        try {
            const data = await openRouter.chat.send({
                model: modelId,
                max_tokens: 200,
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: prompt },
                            { type: "image_url", imageUrl: { url: dataUrl } }
                        ]
                    }
                ],
                stream: false
            });

            const content = data?.choices?.[0]?.message?.content;
            const textContent = extractTextContent(content);
            if (!textContent) {
                throw new Error("OpenRouter returned no content");
            }

            const parsed = parseJsonFromContent(textContent);
            if (!parsed) {
                throw new Error("OpenRouter returned invalid JSON");
            }

            return normalizePrecheck(parsed, modelId, mode);
        } catch (error) {
            if (shouldRetryWithNextModel(error)) {
                lastError = error;
                continue;
            }
            throw error;
        }
    }

    throw lastError || new Error("OpenRouter request failed");
}

function createClient(apiKey, baseUrl) {
    const options = {
        apiKey,
        httpReferer: "https://morphed.app",
        xTitle: "Morphed Backend"
    };
    const normalizedBaseUrl = normalizeBaseUrl(baseUrl);
    if (normalizedBaseUrl) {
        options.serverURL = normalizedBaseUrl;
    }
    return new OpenRouter(options);
}

function normalizeModels(models) {
    if (Array.isArray(models) && models.length > 0) {
        return models;
    }
    if (typeof models === "string" && models.trim().length > 0) {
        return [models.trim()];
    }
    return [DEFAULT_MODEL];
}

function shouldRetryWithNextModel(error) {
    const status = getErrorStatus(error);
    if (!status) return true;
    if (status === 404) {
        return isLikelyModelNotFound(error);
    }
    return status === 429 || status === 502 || status === 503 || status === 504;
}

function getErrorStatus(error) {
    return error?.status || error?.response?.status;
}

function isLikelyModelNotFound(error) {
    const details = [
        error?.message,
        error?.response?.data?.error?.message,
        error?.response?.data?.error?.metadata?.raw
    ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
    return (
        details.includes("no matching route") ||
        details.includes("model specified") ||
        details.includes("model not configured") ||
        details.includes("model not found")
    );
}

function normalizeBaseUrl(baseUrl) {
    if (!baseUrl || typeof baseUrl !== "string") return null;
    const trimmed = baseUrl.trim();
    if (trimmed.length === 0) return null;
    try {
        const url = new URL(trimmed);
        const path = url.pathname.replace(/\/+$/, "");
        const chatSuffixes = ["/chat/completions", "/api/v1/chat/completions", "/v1/chat/completions"];
        for (const suffix of chatSuffixes) {
            if (path.endsWith(suffix)) {
                url.pathname = path.slice(0, -suffix.length) || "/";
                break;
            }
        }
        return url.toString().replace(/\/+$/, "");
    } catch {
        return trimmed;
    }
}

function parseJsonFromContent(content) {
    const trimmed = content.trim();
    try {
        return JSON.parse(trimmed);
    } catch {
        const start = trimmed.indexOf("{");
        const end = trimmed.lastIndexOf("}");
        if (start === -1 || end === -1 || end <= start) {
            return null;
        }
        const candidate = trimmed.slice(start, end + 1);
        try {
            return JSON.parse(candidate);
        } catch {
            return null;
        }
    }
}

function extractTextContent(content) {
    if (!content) return null;
    if (typeof content === "string") {
        return content;
    }
    if (Array.isArray(content)) {
        const textParts = content
            .map((part) => {
                if (!part) return "";
                if (typeof part === "string") return part;
                if (typeof part.text === "string") return part.text;
                return "";
            })
            .filter(Boolean);
        return textParts.length > 0 ? textParts.join("\n") : null;
    }
    if (typeof content === "object" && typeof content.text === "string") {
        return content.text;
    }
    return null;
}

function normalizePrecheck(parsed, modelUsed, mode) {
    const pass = !!parsed?.pass;
    const warnings = normalizeWarnings(parsed?.warnings, mode);
    const debug = typeof parsed?.debug === "string" ? parsed.debug : "";
    let defaultBlockingMessage = "Please upload a clear photo of a single person with a visible face.";
    if (mode === "physique") {
        defaultBlockingMessage = "Please upload a clear photo of a single person with a visible body.";
    }
    const blockingMessage = pass ? null : defaultBlockingMessage;
    return {
        pass,
        blockingMessage,
        warnings,
        debug,
        modelUsed
    };
}

function normalizeWarnings(rawWarnings, mode) {
    if (!Array.isArray(rawWarnings)) return [];
    const normalized = [];
    for (const warning of rawWarnings) {
        const text = String(warning || "").trim();
        if (!text) continue;
        const lower = text.toLowerCase();
        if (mode === "physique" && (lower.includes("face") || lower.includes("facial"))) {
            continue;
        }
        if (mode === "face" && (lower.includes("angle") || lower.includes("tilt") || lower.includes("yaw") || lower.includes("roll"))) {
            continue;
        }
        if (mode === "face" && lower.includes("blur")) {
            const isSevere = ["very", "extreme", "severe", "heavily", "significantly"].some((word) => lower.includes(word));
            if (!isSevere) {
                continue;
            }
        }
        if (lower.includes("backlight") || lower.includes("backlit") || lower.includes("silhouette")) {
            normalized.push("Strong backlight — softer lighting may improve results.");
            continue;
        }
        if (lower.includes("occluded") || lower.includes("obscured") || lower.includes("blocked")) {
            normalized.push("Target area partially occluded — clearer framing may improve results.");
            continue;
        }
        if (lower.includes("blur")) {
            normalized.push("Blurry — a sharper photo may improve results.");
            continue;
        }
        if (lower.includes("low light") || lower.includes("dark") || lower.includes("dim")) {
            normalized.push("Low light — a brighter photo may improve results.");
            continue;
        }
        if (lower.includes("overexposed") || lower.includes("too bright") || lower.includes("blown highlights")) {
            normalized.push("Overexposed — softer lighting may improve results.");
            continue;
        }
        if (lower.includes("small face") || (lower.includes("face") && lower.includes("small"))) {
            normalized.push("Face is small in frame — a closer photo may improve results.");
            continue;
        }
        if (lower.includes("angle") || lower.includes("tilt") || lower.includes("yaw") || lower.includes("roll")) {
            normalized.push("Strong angle — a straighter, front-facing photo may improve results.");
            continue;
        }
    }
    return Array.from(new Set(normalized)).slice(0, 1);
}
