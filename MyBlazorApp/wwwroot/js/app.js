// Creates a temporary link element to trigger file download
function downloadFile(filename, base64Data) {
    const link = document.createElement('a');
    link.download = filename;
    link.href = `data:text/csv;base64,${base64Data}`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}