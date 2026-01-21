// morphed-backend/src/geminiClient.js

import { GoogleGenerativeAI } from "@google/generative-ai";
import { getPromptForMode } from "./prompts.js";

export async function editImageWithGemini(imageBase64, mode, apiKey) {
    if (!apiKey) {
        throw new Error("GEMINI_API_KEY is not set");
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = getPromptForMode(mode);

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
            throw new Error("MODEL_ERROR: No candidates returned from Gemini");
        }

        const firstCandidate = candidates[0];
        const parts = firstCandidate.content?.parts;

        if (!parts || parts.length === 0) {
            throw new Error("MODEL_ERROR: No content parts in Gemini response");
        }

        for (const part of parts) {
            if (part.inlineData && part.inlineData.data) {
                return {
                    imageBase64: part.inlineData.data,
                    mimeType: part.inlineData.mimeType || "image/jpeg"
                };
            }
        }

        throw new Error("MODEL_ERROR: Gemini did not return an image in the response");
    } catch (error) {
        if (error.message.includes("MODEL_ERROR")) {
            throw error;
        }
        if (error.message.includes("API_KEY")) {
            throw new Error("Invalid or missing GEMINI_API_KEY");
        }
        throw new Error(`Gemini API error: ${error.message}`);
    }
}

