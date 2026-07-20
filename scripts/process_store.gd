class_name ProcessStore
extends Node

signal process_added(process: ProcessData)

var processes_by_device: Dictionary = {}

func seed_workstation_a() -> void:
	if processes_by_device.has("workstation_a"):
		return
	processes_by_device["workstation_a"] = [
		ProcessData.new({"id": "system_service", "device_id": "workstation_a", "process_name": "system_service", "user_name": "SYSTEM", "publisher": "System Components", "file_path": "C:/Windows/System32/system_service.exe", "started_at": 0.0, "classification": "Known", "has_network_activity": false, "description": "Core workstation service present before the investigation."}),
		ProcessData.new({"id": "desktop_shell", "device_id": "workstation_a", "process_name": "desktop_shell", "user_name": "analyst.user", "publisher": "Desktop Platform", "file_path": "C:/Program Files/Desktop/desktop_shell.exe", "started_at": 0.0, "classification": "Known", "has_network_activity": false, "description": "Standard interactive desktop shell."}),
		ProcessData.new({"id": "document_client", "device_id": "workstation_a", "process_name": "document_client", "user_name": "analyst.user", "publisher": "Corporate Office", "file_path": "C:/Program Files/Office/document_client.exe", "started_at": 0.0, "classification": "Expected", "has_network_activity": true, "description": "Approved client used for routine document synchronization."})
	]

func add(process: ProcessData) -> void:
	if not processes_by_device.has(process.device_id):
		processes_by_device[process.device_id] = []
	(processes_by_device[process.device_id] as Array).append(process)
	process_added.emit(process)

func get_for_device(device_id: String) -> Array[ProcessData]:
	var result: Array[ProcessData] = []
	if not processes_by_device.has(device_id):
		return result
	for process: ProcessData in processes_by_device[device_id]:
		result.append(process)
	return result
