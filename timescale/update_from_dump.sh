#!/bin/bash

# Имя контейнера TimescaleDB
CONTAINER_NAME="tottalbattle_db"
# Имя пользователя и базы данных
DB_USER="tottalbattle"
DB_NAME="tottalbattle"
# Имя файла дампа
DUMP_FILE="../../tottalbattle.bak/db.dump"
LOG_FILE="restore_$(date +%F_%H-%M-%S).log"

# Проверяем, существует ли файл дампа
if [ ! -f "$DUMP_FILE" ]; then
    echo "Ошибка: Файл дампа '$DUMP_FILE' не найден."
    exit 1
fi

# Проверка доступности контейнера
if ! docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo "Ошибка: Контейнер '$CONTAINER_NAME' не запущен или не существует."
    exit 1
fi

echo "Начало восстановления базы данных..."

# Удаляем базу данных и создаем новую
echo "Удаление и пересоздание базы данных..."
docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "\q" || {
    echo "Ошибка: База данных '$DB_NAME' не готова."
    exit 1
}

# Восстанавливаем базу из дампа (включая схему и данные)
docker exec -i "$CONTAINER_NAME" pg_restore -Fc -v -d "$DB_NAME" -U "$DB_USER" < "$DUMP_FILE" > "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "База данных успешно обновлена."
else
    echo "Ошибка при восстановлении базы данных."
    exit 1
fi
