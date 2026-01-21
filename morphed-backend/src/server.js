// morphed-backend/src/server.js

import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { editImageWithGemini } from "./geminiClient.js";
import { validateEditRequest } from "./validate.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "10mb" }));

app.use((req, res, next) => {
    const requestId = Math.random().toString(36).substring(7);
    req.requestId = requestId;
    console.log(`[${requestId}] ${req.method} ${req.path}`);
    next();
});

app.post("/edit", async (req, res) => {
    const { requestId } = req;
    
    try {
        const validation = validateEditRequest(req.body);
        if (!validation.valid) {
            console.error(`[${requestId}] Validation failed:`, validation.error);
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: validation.error,
                    details: validation.details
                }
            });
        }
        
        const { mode, imageBase64, mimeType } = req.body;
        
        if (!process.env.GEMINI_API_KEY) {
            console.error(`[${requestId}] GEMINI_API_KEY not configured`);
            return res.status(500).json({
                error: {
                    code: "INTERNAL",
                    message: "Server configuration error: GEMINI_API_KEY is not set",
                    details: "Please configure GEMINI_API_KEY in your .env file"
                }
            });
        }
        
        console.log(`[${requestId}] Processing ${mode} mode request`);
        
        const result = await Promise.race([
            editImageWithGemini(imageBase64, mode, process.env.GEMINI_API_KEY),
            new Promise((_, reject) => 
                setTimeout(() => reject(new Error("Request timeout")), 120000)
            )
        ]);
        
        console.log(`[${requestId}] Successfully processed image`);
        
        res.json({
            editedImageBase64: result.imageBase64,
            mimeType: result.mimeType || "image/jpeg"
        });
    } catch (error) {
        console.error(`[${requestId}] Error:`, error.message);
        
        if (error.message.includes("timeout")) {
            return res.status(504).json({
                error: {
                    code: "INTERNAL",
                    message: "Request timeout",
                    details: "The image processing took too long. Please try again."
                }
            });
        }
        
        if (error.message.includes("MODEL_ERROR") || error.message.includes("did not return an image")) {
            return res.status(500).json({
                error: {
                    code: "MODEL_ERROR",
                    message: error.message,
                    details: "The AI model did not return a valid image. Please try again."
                }
            });
        }
        
        res.status(500).json({
            error: {
                code: "INTERNAL",
                message: error.message || "Internal server error",
                details: "An unexpected error occurred while processing your image"
            }
        });
    }
});

// Lightweight usage tracking endpoint (stub – no persistence yet).
app.post("/usage", (req, res) => {
    const { requestId } = req;
    const payload = req.body || {};
    console.log(`[${requestId}] /usage event`, payload);
    return res.json({ ok: true });
});

// Credits decrement endpoint (stub – does not actually enforce credits).
app.post("/credits/decrement", (req, res) => {
    const { requestId } = req;
    const { userId, amount } = req.body || {};
    console.log(`[${requestId}] /credits/decrement userId=${userId} amount=${amount}`);
    return res.json({
        ok: true,
        remainingCredits: 0
    });
});

// Referral tracking endpoint (stub).
app.post("/referral", (req, res) => {
    const { requestId } = req;
    const { code } = req.body || {};
    console.log(`[${requestId}] /referral code=${code}`);
    return res.json({ ok: true });
});

// Basic entitlements endpoint – currently always returns "free" tier.
app.get("/entitlements", (req, res) => {
    const { requestId } = req;
    console.log(`[${requestId}] /entitlements (static free tier)`);
    return res.json({
        tier: "free",
        canUseMaxMode: false,
        canExportHD: false,
        remainingPremiumRenders: 0
    });
});

app.get("/health", (req, res) => {
    res.json({ 
        status: "ok",
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`Morphed backend server running on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
});

