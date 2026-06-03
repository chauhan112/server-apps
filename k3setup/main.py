import os
from flask import Flask, render_template_string, Response, request
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__)

TAILSCALE_KEY = os.getenv("TAILSCALE_KEY")
K3S_TOKEN = os.getenv("K3S_TOKEN")
MASTER_IP = os.getenv("MASTER_IP")

@app.route('/bootstrap')
def bootstrap():
    if not all([TAILSCALE_KEY, K3S_TOKEN, MASTER_IP]):
        return "Error: Missing configuration in .env file", 500

    # Fetch role query parameter, default to 'agent'
    role = request.args.get('role', 'agent')
    if role not in ['server', 'agent']:
        return "Error: Invalid role parameter. Choose 'server' or 'agent'.", 400

    try:
        with open("bootstrap.sh", "r") as f:
            template_content = f.read()
        
        # Inject context variables into template
        rendered_script = render_template_string(
            template_content,
            TAILSCALE_KEY=TAILSCALE_KEY,
            K3S_TOKEN=K3S_TOKEN,
            MASTER_IP=MASTER_IP,
            ROLE=role
        )
        
        return Response(rendered_script, mimetype='text/x-shellscript')
        
    except FileNotFoundError:
        return "Error: bootstrap.sh template file not found", 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8082)