class_name NetworkData
extends RefCounted

static func create_devices() -> Array[DeviceData]:
	return [
		DeviceData.new({"id": "internet", "display_name": "Internet", "category": "External Network", "operational_role": "Upstream connectivity", "zone": "Perimeter", "address": "198.51.100.0/24", "description": "Managed external route for corporate services.", "importance": "High", "position": Vector2(126, 324), "kind": "internet"}),
		DeviceData.new({"id": "firewall", "display_name": "Firewall", "category": "Security Gateway", "operational_role": "Network boundary control", "zone": "Perimeter", "address": "10.0.0.1", "description": "Primary gateway between external and internal zones.", "importance": "Critical", "position": Vector2(330, 324), "kind": "firewall"}),
		DeviceData.new({"id": "workstation_a", "display_name": "Workstation A", "category": "Endpoint", "operational_role": "Finance workstation", "zone": "Corporate LAN", "address": "10.20.14.21", "description": "Managed endpoint assigned to the finance team.", "importance": "Medium", "position": Vector2(548, 164), "kind": "workstation"}),
		DeviceData.new({"id": "workstation_b", "display_name": "Workstation B", "category": "Endpoint", "operational_role": "Operations workstation", "zone": "Corporate LAN", "address": "10.20.14.34", "description": "Managed endpoint assigned to operations.", "importance": "Medium", "position": Vector2(548, 470), "kind": "workstation"}),
		DeviceData.new({"id": "file_server", "display_name": "File Server", "category": "Server", "operational_role": "Department file storage", "zone": "Server Zone", "address": "10.30.8.12", "description": "Central repository for approved corporate documents.", "importance": "High", "position": Vector2(758, 324), "kind": "server"}),
		DeviceData.new({"id": "backup_server", "display_name": "Backup Server", "category": "Backup Infrastructure", "operational_role": "Protected data backup", "zone": "Recovery Zone", "address": "10.40.2.9", "description": "Maintains scheduled copies of business data.", "importance": "High", "position": Vector2(900, 482), "kind": "backup"})
	]

static func create_links() -> Array[PackedStringArray]:
	return [PackedStringArray(["internet", "firewall"]), PackedStringArray(["firewall", "workstation_a"]), PackedStringArray(["firewall", "workstation_b"]), PackedStringArray(["firewall", "file_server"]), PackedStringArray(["file_server", "backup_server"])]
