/// A ready-made kind of saved place (gym, school…). The server has no such
/// type: a preset is saved as an `other` address whose `label` is the
/// preset's name, and recognised again by that label.
enum SavedPlacePreset { gym, school, university, family }
