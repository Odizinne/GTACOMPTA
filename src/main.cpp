#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "employeemodel.h"
#include "transactionmodel.h"
#include "clientmodel.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
    QGuiApplication app(argc, argv);

    qmlRegisterType<EmployeeModel>("Odizinne.GTACOMPTA", 1, 0, "EmployeeModel");
    qmlRegisterType<TransactionModel>("Odizinne.GTACOMPTA", 1, 0, "TransactionModel");
    qmlRegisterType<ClientModel>("Odizinne.GTACOMPTA", 1, 0, "ClientModel");

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
