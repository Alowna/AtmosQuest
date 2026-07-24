extends TextureButton

# The directory where reports will be saved. Must use user:// for exported games.
const REPORTS_DIR = "user://reports"
const MAX_REPORTS = 3

func _ready() -> void:
	# Connects the button's own pressed signal to the handler function
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Ensure the directory exists before trying to read/write
	DirAccess.make_dir_recursive_absolute(REPORTS_DIR)
	
	# Clean up old reports to maintain the limit
	manage_report_history()
	
	# Path to your HTML template (res:// is fine for reading assets)
	var template_path = "res://assets/reports/report_template.html" 
	
	# Generate a unique file name using the current time
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var output_path = REPORTS_DIR + "/game_report_" + timestamp + ".html"
	
	# 1. Open the template for reading
	var file = FileAccess.open(template_path, FileAccess.READ)
	if not file:
		print("Error: Could not find template at ", template_path)
		return
		
	var html_content = file.get_as_text()
	file.close()
	
	# 2. Format variables into human-readable strings
	var alive_text = "Sobreviveu e saiu de órbita!" if PlayerConfig.isAlive else "Nave destruída!"
	var death_obj_text = PlayerConfig.collisionDeathObject if (not PlayerConfig.isAlive and PlayerConfig.collisionDeathObject != "Unknown") else "Nenhum"
	var layer_name = get_atmosphere_name(PlayerConfig.atmosLayer)
	var total_questions = PlayerConfig.correctAnswers + PlayerConfig.wrongAnswers
	var game_result_text = "Vitória" if PlayerConfig.isAlive else "Derrota"
	
	# 3. Build HTML lists for correct and wrong answers
	var correct_html = ""
	for q_id in PlayerConfig.correctAnswersIds:
		var q_data = get_question_by_id(q_id)
		if not q_data.is_empty():
			var correct_letter = q_data.correct_answer
			var answer_text = get_answer_text(q_data, correct_letter)
			correct_html += "<li><strong>%s</strong><br><span class='success'>Resposta: %s</span><br><em>%s</em></li><br>" % [q_data.statement, answer_text, q_data.answer_explain]
			
	if correct_html == "": 
		correct_html = "<li>Nenhuma questão respondida corretamente.</li>"

	var wrong_html = ""
	for q_id in PlayerConfig.wrongAnswersIds:
		var q_data = get_question_by_id(q_id)
		if not q_data.is_empty():
			var correct_letter = q_data.correct_answer
			var answer_text = get_answer_text(q_data, correct_letter)
			wrong_html += "<li><strong>%s</strong><br><span class='danger'>A resposta correta era: %s</span><br><em>%s</em></li><br>" % [q_data.statement, answer_text, q_data.answer_explain]
			
	if wrong_html == "": 
		wrong_html = "<li>Nenhuma questão errada. Perfeito!</li>"

	# 4. Replace {{tag}} place-holders in HTML
	# Ensure you use your fallback logic for username if it can be empty
	var current_username = PlayerConfig.username if PlayerConfig.username != "" else "Jogador"
	
	html_content = html_content.replace("{{username}}", current_username)
	html_content = html_content.replace("{{isAlive}}", alive_text)
	html_content = html_content.replace("{{lives}}", str(PlayerConfig.lives))
	html_content = html_content.replace("{{colisionDeathObject}}", death_obj_text)
	html_content = html_content.replace("{{points}}", str(PlayerConfig.points))
	html_content = html_content.replace("{{maxAltitude}}", str(PlayerConfig.maxAltitude))
	html_content = html_content.replace("{{atmosLayer}}", layer_name)
	html_content = html_content.replace("{{correctAnswers}}", str(PlayerConfig.correctAnswers))
	html_content = html_content.replace("{{wrongAnswers}}", str(PlayerConfig.wrongAnswers))
	html_content = html_content.replace("{{totalQuestions}}", str(total_questions))
	html_content = html_content.replace("{{result}}", game_result_text)
	
	# Inject generated question lists
	html_content = html_content.replace("{{correctAnswersList}}", correct_html)
	html_content = html_content.replace("{{wrongAnswersList}}", wrong_html)

	# 5. Write out the final HTML file
	var save_file = FileAccess.open(output_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(html_content)
		save_file.close()
		print("Relatório salvo com sucesso em: ", output_path)
		
		# 6. Open the file externally (PC Browser or Android Intent)
		open_report_externally(output_path)
	else:
		print("Erro ao tentar salvar o arquivo em: ", output_path)

# ==========================================
# FILE MANAGEMENT LOGIC
# ==========================================

# Checks the reports folder. If there are 3 or more reports, deletes the oldest ones
# until there is room for the new report.
func manage_report_history() -> void:
	var dir = DirAccess.open(REPORTS_DIR)
	if not dir: 
		return
		
	var files_data = []
	
	# List all HTML files in the reports directory
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".html"):
			var full_path = REPORTS_DIR + "/" + file_name
			files_data.append({
				"path": full_path,
				"time": FileAccess.get_modified_time(full_path) # Gets UNIX timestamp of file modification
			})
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# Sort files by time ascending (oldest files at the beginning of the array)
	files_data.sort_custom(func(a, b): return a["time"] < b["time"])
	
	# Delete oldest files if we reached or exceeded the maximum allowed
	# We use MAX_REPORTS - 1 because we are about to create a new one
	while files_data.size() >= MAX_REPORTS:
		var oldest_file = files_data.pop_front() # Removes and returns the first element (the oldest)
		DirAccess.remove_absolute(oldest_file["path"])
		print("Relatório antigo deletado: ", oldest_file["path"])

# Uses the OS to open the file in the default application
func open_report_externally(local_path: String) -> void:
	# globalize_path converts 'user://...' to an absolute system path (e.g., C:/Users/... or /data/user/...)
	var global_path = ProjectSettings.globalize_path(local_path)
	
	# shell_open triggers the default OS behavior for this file type
	var error = OS.shell_open("file://" + global_path)
	
	if error != OK:
		print("Falha ao abrir o relatório externamente. Código de erro: ", error)

# --- HELPER FUNCTIONS ---

func get_question_by_id(id: int) -> Dictionary:
	for q in PlayerConfig.all_questions:
		if q.id == id:
			return q
	return {}

func get_answer_text(q: Dictionary, correct_letter: String) -> String:
	match correct_letter:
		"A": return q.answer_a
		"B": return q.answer_b
		"C": return q.answer_c
		"D": return q.answer_d
	return "Resposta desconhecida"

func get_atmosphere_name(layer_index: int) -> String:
	match layer_index:
		0: return "Troposfera"
		1: return "Estratosfera"
		2: return "Mesosfera"
		3: return "Termosfera"
		4: return "Exosfera"
		_: return "camada desconhecida"
