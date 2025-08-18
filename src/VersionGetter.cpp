#include "VersionGetter.h"
#include "version.h"

VersionGetter* VersionGetter::m_instance = nullptr;

VersionGetter::VersionGetter(QObject* parent)
    : QObject(parent)
{
    m_instance = this;
}

VersionGetter::~VersionGetter()
{
    if (m_instance == this) {
        m_instance = nullptr;
    }
}

VersionGetter* VersionGetter::create(QQmlEngine* qmlEngine, QJSEngine* jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    if (!m_instance) {
        m_instance = new VersionGetter();
    }
    return m_instance;
}

VersionGetter* VersionGetter::instance()
{
    return m_instance;
}

QString VersionGetter::getAppVersion() const
{
    return APP_VERSION_STRING;
}

QString VersionGetter::getQtVersion() const
{
    return QT_VERSION_STRING;
}

QString VersionGetter::getCommitHash() const
{
    return QString(GIT_COMMIT_HASH);
}

QString VersionGetter::getBuildTimestamp() const
{
    return QString(BUILD_TIMESTAMP);
}
