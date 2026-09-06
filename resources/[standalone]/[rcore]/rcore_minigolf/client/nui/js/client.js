window.addEventListener("message", (event) => {
    let data = event.data;
    if (data.action == "mugconvert") {
        ToDataURL(data.txdName, function (base64) {
            fetch(`https://${GetParentResourceName()}/mugcallback`, {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=UTF-8" },
                body: JSON.stringify({
                    base64: base64,
                    handle: event.data.handle,
                    id: event.data.id,
                }),
            });
        });
    }
});

function ToDataURL(url, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onload = function () {
        var reader = new FileReader();
        reader.onloadend = function () {
            callback(reader.result);
        };
        reader.readAsDataURL(xhr.response);
    };
    xhr.open("GET", url);
    xhr.responseType = "blob";
    xhr.send();
}
