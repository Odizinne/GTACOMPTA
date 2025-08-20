#ifndef VERSIONGETTER_H
#define VERSIONGETTER_H

#include <QObject>
#include <QQmlEngine>
#include <QtQml/qqmlregistration.h>

class VersionGetter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit VersionGetter(QObject* parent = nullptr);
    ~VersionGetter() override;

    static VersionGetter* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);
    static VersionGetter* instance();

    Q_INVOKABLE QString getAppVersion() const;
    Q_INVOKABLE QString getQtVersion() const;
    Q_INVOKABLE QString getCommitHash() const;
    Q_INVOKABLE QString getBuildTimestamp() const;

private:
    static VersionGetter* m_instance;
};

#endif // VERSIONGETTER_H
