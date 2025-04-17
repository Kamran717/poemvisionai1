// Frame data and styling information

const frameStyles = {
    // Classic frame - simple solid border
    classic: {
        name: "Classic",
        description: "A timeless solid border frame that works well with any image.",
        borderWidth: 20,
        borderColor: "#192a56",
        backgroundColor: "#f5f6fa",
        textColor: "#000000",
        fontFamily: "Georgia, serif",
        hasDecorativeCorners: true
    },

    // Elegant frame - sophisticated design with decorative corners
    elegant: {
        name: "Elegant",
        description: "A sophisticated frame with subtle decorative elements at the corners.",
        borderWidth: 30,
        borderColor: "#192a56",
        backgroundColor: "#f5f6fa",
        textColor: "#273c75",
        fontFamily: "Garamond, serif",
        hasDecorativeCorners: true
    },

    // Vintage frame - weathered, antique look
    vintage: {
        name: "Vintage",
        description: "A weathered, antique-looking frame with warm tones.",
        borderWidth: 25,
        borderColor: "#8B4513",
        backgroundColor: "#F5F5DC",
        textColor: "#3D2314",
        fontFamily: "Times New Roman, serif",
        hasTexture: true
    },

    // Minimalist frame - thin, simple lines
    minimalist: {
        name: "Minimalist",
        description: "A clean, simple frame with thin lines for a modern look.",
        borderWidth: 10,
        borderColor: "#dddddd",
        backgroundColor: "#ffffff",
        textColor: "#333333",
        fontFamily: "Arial, sans-serif"
    },

    // Ornate frame - decorative, elaborate design
    ornate: {
        name: "Ornate",
        description: "An elaborate, decorative frame with intricate patterns.",
        borderWidth: 40,
        borderColor: "#800000",
        backgroundColor: "#FFFFFF",
        textColor: "#4d0000",
        fontFamily: "Baskerville, serif",
        hasPattern: true
    },

    // No frame option
    none: {
        name: "No Frame",
        description: "Display your image and poem without a frame.",
        borderWidth: 0,
        borderColor: "transparent",
        backgroundColor: "transparent",
        textColor: "#000000",
        fontFamily: "Georgia, serif"
    }
};

// CSS styles for frame previews
document.addEventListener('DOMContentLoaded', function() {
    // This will be applied when the document is loaded
    // For preview purposes only - actual frames are handled by the server
});

// Export the frameStyles object if using modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { frameStyles };
}
