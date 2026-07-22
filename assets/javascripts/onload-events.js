// Subscribe to MkDocs navigation events
document$.subscribe(({ body }) => {
    // Process Drawio
    GraphViewer.processElements();

    // Process WaveDrom
    WaveDrom.ProcessAll();

    // Process MathJax
    if (window.MathJax && window.MathJax.typesetPromise) {
        window.MathJax.typesetPromise([body]).catch((err) => console.error('MathJax error:', err));
    }
});

// MathJax Configuration
window.MathJax = {
    tex: {
        inlineMath: [["\\(", "\\)"]],
        displayMath: [["\\[", "\\]"]],
        processEscapes: true,
        processEnvironments: true
    },
    options: {
        ignoreHtmlClass: ".*|",
        processHtmlClass: "arithmatex"
    }
};
