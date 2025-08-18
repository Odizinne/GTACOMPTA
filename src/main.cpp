#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
    QGuiApplication app(argc, argv);

    app.setOrganizationName("Odizinne");
    app.setApplicationName("GTACOMPTA");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Odizinne.GTACOMPTA", "Main");

    return app.exec();
}
