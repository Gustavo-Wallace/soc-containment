class_name EvidenceStore
extends Node

const EvidenceDataType = preload("res://scripts/evidence_data.gd")

signal evidence_added(evidence: EvidenceDataType)
var evidence: Array[EvidenceDataType] = []

func add(item: EvidenceDataType) -> void:
	for existing: EvidenceDataType in evidence:
		if existing.id == item.id:
			return
	evidence.append(item)
	evidence_added.emit(item)

func has(id: String) -> bool:
	for item: EvidenceDataType in evidence:
		if item.id == id:
			return true
	return false

func hypothesis_confidence() -> String:
	if evidence.size() >= 2:
		return "High"
	if evidence.size() == 1:
		return "Moderate"
	return "Low"
