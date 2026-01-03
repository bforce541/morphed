// geminiClient.js

import { GoogleGenerativeAI } from "@google/generative-ai";

const MAX_PROMPT = `You are a professional photo editor specializing in masculine enhancement. Edit this photo with aggressive but realistic enhancements:

- Sharpen and define the jawline subtly
- Enhance eye intensity and clarity
- Clean up skin while preserving natural texture
- Enhance beard definition if present
- Slightly widen shoulders and make chest appear fuller
- Tighten waist area subtly
- Apply dramatic but natural lighting and contrast
- Keep the person's identity and ethnicity unchanged
- Do not add any text, logos, or watermarks
- Avoid grotesque distortions or cartoon-like muscles
- Keep it realistic but "clout" aesthetic is acceptable

Return only the edited image, no text explanations.`;

const CLEAN_PROMPT = `You are a professional photo editor specializing in natural, subtle enhancements. Edit this photo with minimal, natural improvements:

- Improve lighting naturally
- Add mild jaw definition if appropriate
- Clean up skin while preserving all natural texture
- Make minimal body adjustments if any
- Keep the person's identity completely unchanged
- Do not add any text, logos, or watermarks
- Avoid any distortions or obvious edits
- Keep it looking completely natural

Return only the edited image, no text explanations.`;

export async function editImageWithGemini(imageBase64, mode, apiKey) {
    if (!apiKey) {
        throw new Error("GEMINI_API_KEY is not set");
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = mode === "max" ? MAX_PROMPT : CLEAN_PROMPT;

    const imageData = {
        inlineData: {
            data: imageBase64,
            mimeType: "image/jpeg"
        }
    };

    try {
        const result = await model.generateContent([prompt, imageData]);
        const response = await result.response;

        const candidates = response.candidates;
        if (!candidates || candidates.length === 0) {
            throw new Error("No candidates returned from Gemini");
        }

        const firstCandidate = candidates[0];
        const parts = firstCandidate.content?.parts;

        if (!parts || parts.length === 0) {
            throw new Error("No content parts in Gemini response");
        }

        for (const part of parts) {
            if (part.inlineData) {
                return {
                    imageBase64: part.inlineData.data,
                    mimeType: part.inlineData.mimeType || "image/jpeg"
                };
            }
        }

        throw new Error("Gemini did not return an image in the response");
    } catch (error) {
        if (error.message.includes("GEMINI_API_KEY")) {
            throw error;
        }
        if (error.message.includes("did not return an image")) {
            throw error;
        }
        throw new Error(`Gemini API error: ${error.message}`);
    }
}

