// morphed-backend/src/prompts.js

// PLACEHOLDER PROMPTS - Replace these with your actual prompts when ready
// These are safe defaults that will work but produce generic results

const PRESENCE_PROMPT = `You are a professional photo editor. Edit this photo to optimize posture, proportions, and framing:

- Optimize upright posture and body positioning
- Adjust camera angle for better framing
- Enhance shoulder framing and presence
- Apply subtle vertical elongation (optical, not literal)
- Keep the person's identity completely unchanged
- Do not add any text, logos, watermarks, or tattoos
- Avoid distortions or unrealistic changes
- Do not change ethnicity, age, or facial structure

Return only the edited image as base64-encoded JPEG, no text explanations.`;

const PHYSIQUE_PROMPT = `You are a professional photo editor. Edit this photo to emphasize visual definition through lighting, shadows, and fit:

- Emphasize V-taper silhouette
- Enhance chest and shoulder lighting
- Improve shirt fit (wrinkles → structure)
- Do not add fake muscles or unrealistic proportions
- Keep the person's identity completely unchanged
- Do not add any text, logos, watermarks, or tattoos
- Avoid distortions or cartoon-like enhancements
- Do not change ethnicity, age, or facial structure

Return only the edited image as base64-encoded JPEG, no text explanations.`;

const FACE_PROMPT = `You are a professional photo editor. Edit this photo to improve structure and clarity:

- Enhance jaw and cheekbone definition
- Improve eye clarity and intensity
- Polish skin texture while preserving natural look
- Keep the person's identity completely unchanged
- Do not add any text, logos, watermarks, or tattoos
- Avoid distortions or unrealistic changes
- Do not change ethnicity, age, or facial structure

Return only the edited image as base64-encoded JPEG, no text explanations.`;

const STYLE_PROMPT = `You are a professional photo editor. Edit this photo to improve outfit sharpness and silhouette:

- Improve clothing drape and fit
- Enhance cleaner lines and structure
- Boost contrast and texture for visual pop
- Keep the person's identity completely unchanged
- Do not add any text, logos, watermarks, or tattoos
- Avoid distortions or unrealistic changes
- Do not change ethnicity, age, or facial structure

Return only the edited image as base64-encoded JPEG, no text explanations.`;

/**
 * Get the prompt for a given edit mode
 * @param {string} mode - One of: presence, physique, face, style
 * @returns {string} The prompt text for the mode
 */
export function getPromptForMode(mode) {
    switch (mode) {
        case "presence":
            return PRESENCE_PROMPT;
        case "physique":
            return PHYSIQUE_PROMPT;
        case "face":
            return FACE_PROMPT;
        case "style":
            return STYLE_PROMPT;
        default:
            throw new Error(`Invalid mode: ${mode}. Must be one of: presence, physique, face, style`);
    }
}
