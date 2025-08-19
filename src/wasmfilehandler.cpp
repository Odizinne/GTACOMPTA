#include "wasmfilehandler.h"
#include <QDebug>

#ifdef Q_OS_WASM
#include <emscripten.h>
#include <emscripten/html5.h>

static WasmFileHandler* g_wasmFileHandler = nullptr;

extern "C" {
EMSCRIPTEN_KEEPALIVE void saveFileSelectedCallback(const char* fileName) {
    qDebug() << "saveFileSelectedCallback called with:" << fileName;
    if (g_wasmFileHandler) {
        QString fileNameStr = QString::fromUtf8(fileName);
        emit g_wasmFileHandler->saveFileSelected(fileNameStr);
    }
}

EMSCRIPTEN_KEEPALIVE void loadFileSelectedCallback(const char* content) {
    qDebug() << "loadFileSelectedCallback called";
    if (g_wasmFileHandler) {
        QString contentStr = QString::fromUtf8(content);
        qDebug() << "Emitting loadFileSelected signal with content length:" << contentStr.length();
        emit g_wasmFileHandler->loadFileSelected(contentStr);
    }
}
}
#endif

WasmFileHandler::WasmFileHandler(QObject *parent) : QObject(parent)
{
#ifdef Q_OS_WASM
    g_wasmFileHandler = this;
    qDebug() << "WasmFileHandler created";
#endif
}

WasmFileHandler* WasmFileHandler::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    static WasmFileHandler* instance = new WasmFileHandler();
    return instance;
}

void WasmFileHandler::openSaveDialog(const QString& defaultName, const QString& content)
{
    qDebug() << "openSaveDialog called with name:" << defaultName;
#ifdef Q_OS_WASM
    QByteArray nameBytes = defaultName.toUtf8();
    QByteArray contentBytes = content.toUtf8();

    EM_ASM({
        var fileName = UTF8ToString($0);
        var content = UTF8ToString($1);

        // Create blob with the content
        var blob = new Blob([content], { type: 'application/octet-stream' });

        // Create download link
        var link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = fileName;

        // Trigger download
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // Clean up
        URL.revokeObjectURL(link.href);

        // Notify that save was triggered
        var len = lengthBytesUTF8(fileName) + 1;
        var ptr = _malloc(len);
        stringToUTF8(fileName, ptr, len);
        Module._saveFileSelectedCallback(ptr);
        _free(ptr);
    }, nameBytes.constData(), contentBytes.constData());
#else
    qDebug() << "Not WebAssembly platform";
#endif
}

void WasmFileHandler::openLoadDialog()
{
    qDebug() << "openLoadDialog called";
#ifdef Q_OS_WASM
    EM_ASM({
        var input = document.getElementById('loadFileInput');
        if (!input) {
            input = document.createElement('input');
            input.type = 'file';
            input.id = 'loadFileInput';
            input.accept = '.gco';
            input.style.display = 'none';
            document.body.appendChild(input);
        }

        input.onchange = function(e) {
            var file = e.target.files[0];
            if (file) {
                var reader = new FileReader();
                reader.onload = function(event) {
                    var content = event.target.result;
                    var len = lengthBytesUTF8(content) + 1;
                    var ptr = _malloc(len);
                    stringToUTF8(content, ptr, len);
                    Module._loadFileSelectedCallback(ptr);
                    _free(ptr);
                };
                reader.readAsText(file);
            }
        };
        input.click();
    });
#else
    qDebug() << "Not WebAssembly platform";
#endif
}
