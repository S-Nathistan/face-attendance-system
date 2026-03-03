from flask import Flask
from flask_compress import Compress
from waitress import serve

def create_app(config_filename):
    app = Flask(__name__)
    app.config.from_object(config_filename)

    Compress(app)

    from app import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    # from Model import db
    # db.init_app(app)

    return app


if __name__ == "__main__":
    app = create_app("config")
    # app.run(debug=True , host="0.0.0.0", port=5000)
    # app.run(host="0.0.0.0", port=5000)
    serve(app, host='0.0.0.0', port=5000)