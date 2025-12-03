// Drawio
document$.subscribe(({ body }) => {
    GraphViewer.processElements()
})

// Wavedrom
window.addEventListener("load", function () {
    WaveDrom.ProcessAll();
});
