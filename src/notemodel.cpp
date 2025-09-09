#include "notemodel.h"

NoteModel::NoteModel(QObject *parent)
    : BaseModel("notes.json", parent)
    , m_content("")
{
}

int NoteModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 1; // Always one virtual row to satisfy BaseModel interface
}

QVariant NoteModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(index);
    Q_UNUSED(role);
    return QVariant(); // Not used in this implementation
}

QHash<int, QByteArray> NoteModel::roleNames() const
{
    return QHash<int, QByteArray>(); // Not used in this implementation
}

QString NoteModel::content() const
{
    return m_content;
}

void NoteModel::setContent(const QString &content)
{
    if (m_content != content) {
        m_content = content;
        emit contentChanged();
        saveToFile();
    }
}

QJsonObject NoteModel::entryToJson(int index) const
{
    Q_UNUSED(index);
    QJsonObject obj;
    obj["content"] = m_content;
    return obj;
}

void NoteModel::entryFromJson(const QJsonObject &obj)
{
    m_content = obj["content"].toString("");
    emit contentChanged();
}

void NoteModel::addEntryToModel()
{
    // Not used in this implementation
}

void NoteModel::removeEntryFromModel(int index)
{
    Q_UNUSED(index);
    // Not used in this implementation
}

void NoteModel::clearModel()
{
    m_content = "";
    emit contentChanged();
}

void NoteModel::performSort()
{
    // Not used in this implementation - single entry
}
