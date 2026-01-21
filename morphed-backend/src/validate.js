// morphed-backend/src/validate.js

const MAX_IMAGE_SIZE_BYTES = 6 * 1024 * 1024; // 6MB

export function validateEditRequest(body) {
    if (!body) {
        return {
            valid: false,
            error: "Request body is required",
            details: "The request must include a JSON body"
        };
    }

    const { mode, imageBase64, mimeType } = body;

    if (!mode) {
        return {
            valid: false,
            error: "mode is required",
            details: "The 'mode' field must be present and set to 'max' or 'clean'"
        };
    }

    if (mode !== "max" && mode !== "clean") {
        return {
            valid: false,
            error: "Invalid mode",
            details: `Mode must be 'max' or 'clean', received: ${mode}`
        };
    }

    if (!imageBase64) {
        return {
            valid: false,
            error: "imageBase64 is required",
            details: "The 'imageBase64' field must contain a base64-encoded image"
        };
    }

    if (typeof imageBase64 !== "string") {
        return {
            valid: false,
            error: "imageBase64 must be a string",
            details: "The 'imageBase64' field must be a string containing base64 data"
        };
    }

    if (!mimeType) {
        return {
            valid: false,
            error: "mimeType is required",
            details: "The 'mimeType' field must be present (e.g., 'image/jpeg')"
        };
    }

    if (mimeType !== "image/jpeg" && mimeType !== "image/png") {
        return {
            valid: false,
            error: "Invalid mimeType",
            details: `MimeType must be 'image/jpeg' or 'image/png', received: ${mimeType}`
        };
    }

    try {
        const imageBuffer = Buffer.from(imageBase64, "base64");
        const imageSize = imageBuffer.length;

        if (imageSize === 0) {
            return {
                valid: false,
                error: "Invalid image data",
                details: "The base64-encoded image data is empty"
            };
        }

        if (imageSize > MAX_IMAGE_SIZE_BYTES) {
            return {
                valid: false,
                error: "Image too large",
                details: `Image size (${(imageSize / 1024 / 1024).toFixed(2)}MB) exceeds maximum allowed size of ${MAX_IMAGE_SIZE_BYTES / 1024 / 1024}MB`
            };
        }
    } catch (error) {
        return {
            valid: false,
            error: "Invalid base64 encoding",
            details: `Failed to decode base64 image data: ${error.message}`
        };
    }

    return { valid: true };
}

