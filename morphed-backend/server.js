// server.js

import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { editImageWithGemini } from "./geminiClient.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB

app.use(cors());
app.use(express.json({ limit: "15mb" }));

app.post("/edit", async (req, res) => {
    try {
        const { mode, imageBase64, mimeType } = req.body;

        if (!mode) {
            return res.status(400).json({ error: "mode is required" });
        }

        if (mode !== "max" && mode !== "clean") {
            return res.status(400).json({ error: "mode must be 'max' or 'clean'" });
        }

        if (!imageBase64) {
            return res.status(400).json({ error: "imageBase64 is required" });
        }

        if (!mimeType) {
            return res.status(400).json({ error: "mimeType is required" });
        }

        if (mimeType !== "image/jpeg" && mimeType !== "image/png") {
            return res.status(400).json({ error: "mimeType must be 'image/jpeg' or 'image/png'" });
        }

        const imageBuffer = Buffer.from(imageBase64, "base64");
        if (imageBuffer.length > MAX_IMAGE_SIZE) {
            return res.status(400).json({ error: `Image size exceeds ${MAX_IMAGE_SIZE / 1024 / 1024}MB limit` });
        }

        if (!process.env.GEMINI_API_KEY) {
            return res.status(500).json({ error: "GEMINI_API_KEY is not configured" });
        }

        const result = await editImageWithGemini(
            imageBase64,
            mode,
            process.env.GEMINI_API_KEY
        );

        res.json({
            editedImageBase64: result.imageBase64,
            mimeType: result.mimeType || "image/jpeg"
        });
    } catch (error) {
        console.error("Error processing image:", error);
        res.status(500).json({ error: error.message || "Internal server error" });
    }
});

app.get("/health", (req, res) => {
    res.json({ status: "ok" });
});

app.listen(PORT, () => {
    console.log(`Morphed backend server running on http://localhost:${PORT}`);
});

