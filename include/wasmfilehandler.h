#ifndef WASMFILEHANDLER_H
#define WASMFILEHANDLER_H

#include <QObject>
#include <QtQml/qqml.h>

class WasmFileHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static WasmFileHandler* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

public slots:
    void openSaveDialog(const QString& defaultName, const QString& content);
    void openLoadDialog();

signals:
    void saveFileSelected(const QString& fileName);
    void loadFileSelected(const QString& content);

private:
    explicit WasmFileHandler(QObject *parent = nullptr);
};

#endif // WASMFILEHANDLER_H
