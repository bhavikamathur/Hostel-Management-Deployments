#!/bin/bash
echo "Running DB migrations (db.create_all)"
python3 - << 'EOF'
from app import db, app
with app.app_context():
    db.create_all()
    print("Tables created successfully!")
EOF
