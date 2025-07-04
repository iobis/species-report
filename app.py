import os
import requests
import subprocess
import shutil
from flask import Flask, request, render_template, send_file, after_this_request, url_for
from uuid import uuid4

app = Flask(__name__)
app.config["REPORT_DIR"] = "static/reports"
os.makedirs(app.config["REPORT_DIR"], exist_ok=True)

@app.route("/", methods=["GET", "POST"])
def index():
    valid_species = []
    invalid_ids = []
    color_schemes = ["blue", "green", "orange", "red"]

    if request.method == "POST":
        if "check_species" in request.form:
            aphiaids_raw = request.form.get("aphiaids", "")
            aphiaids = [aid.strip() for aid in aphiaids_raw.split(",") if aid.strip().isdigit()]
            for aid in aphiaids:
                response = requests.get(f"https://api.obis.org/v3/taxon/{aid}")
                if response.status_code == 200:
                    data = response.json()
                    if data["total"] > 0:
                        species_name = data["results"][0]["scientificName"]
                        valid_species.append((aid, species_name))
                    else:
                        invalid_ids.append(aid)
                else:
                    invalid_ids.append(aid)

            return render_template("index.html", valid_species=valid_species, invalid_ids=invalid_ids,
                                   color_schemes=color_schemes)

        elif "generate_report" in request.form:
            aphiaids = request.form.getlist("valid_aphiaids")
            color = request.form.get("color")
            output_type = request.form.get("output_type")
            if output_type == "dynamic":
                output_type = True
            else:
                output_type = False
            output_paths = []

            for aid in aphiaids:
                file_id = f"obis_species_ds_{aid}"#uuid4().hex
                html_name = f"{file_id}.html"
                pdf_name = f"{file_id}.pdf"

                subprocess.run([
                    "quarto", "render", "species-report-model-v3.qmd",
                    "--to", "html",
                    "--output", html_name,
                    "-P", f"aphiaid:{aid}",
                    "-P", f"colorschema:{color}",
                    "-P", f"dynamic:{output_type}"
                ], check=True)

                subprocess.run([
                    "Rscript", "-e",
                    f"pagedown::chrome_print('{html_name}', '{pdf_name}')"
                ], check=True)

                # Move files to static/reports
                html_dest = os.path.join(app.config["REPORT_DIR"], html_name)
                pdf_dest = os.path.join(app.config["REPORT_DIR"], pdf_name)
                shutil.move(html_name, html_dest)
                shutil.move(pdf_name, pdf_dest)

                output_paths.append(pdf_dest)

            # Create ZIP if multiple reports
            if len(output_paths) > 1:
                zip_path = os.path.join(app.config["REPORT_DIR"], "reports.zip")
                shutil.make_archive(zip_path.replace(".zip", ""), 'zip', app.config["REPORT_DIR"])
                download_file = "reports.zip"
            else:
                download_file = os.path.basename(output_paths[0])

            return render_template("index.html", valid_species=None, invalid_ids=None,
                                   color_schemes=color_schemes,
                                   download_file=download_file)

    return render_template("index.html", valid_species=None, invalid_ids=None, color_schemes=color_schemes)

@app.route("/download/<filename>")
def download_report(filename):
    path = os.path.join(app.config["REPORT_DIR"], filename)

    @after_this_request
    def cleanup(response):
        try:
            # Delete the downloaded file
            if os.path.exists(path):
                os.remove(path)

            # Also delete the corresponding HTML file if it's a PDF
            if filename.endswith(".pdf"):
                html_path = path.replace(".pdf", ".html")
                if os.path.exists(html_path):
                    os.remove(html_path)

            # If it's a ZIP, remove the folder contents too
            if filename == "reports.zip":
                for f in os.listdir(app.config["REPORT_DIR"]):
                    if f.endswith(".pdf") or f.endswith(".html"):
                        os.remove(os.path.join(app.config["REPORT_DIR"], f))
        except Exception as e:
            print(f"Cleanup error: {e}")
        return response

    return send_file(path, as_attachment=True)
