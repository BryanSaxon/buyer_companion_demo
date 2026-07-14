# Predefined list of production home builders offered on the intake form.
# Each builder maps a display name to a logo asset (served by Propshaft from
# app/assets/images). This is a static registry, not an ActiveRecord model.
class Builder
  # [ display name, logo asset, [prior/alias names] ]. Aliases keep leads that
  # were created under an old name matching after a rename, so their logo
  # survives (e.g. a "SIG Homes" lead still resolves after the Signature rename).
  ENTRIES = [
    [ "Chesapeake Homes",       "builders/chesapeake-homes.svg" ],
    [ "Classic Homes",          "builders/classic-homes.svg" ],
    [ "Eastbrook Homes",        "builders/eastbrook-homes.webp" ],
    [ "Grand Homes",            "builders/grand-homes.png" ],
    [ "Keystone Custom Homes",  "builders/keystone-homes.png" ],
    [ "Pahlisch Homes",         "builders/pahlisch-homes.png" ],
    [ "Robert Thomas Homes",    "builders/robert-thomas-homes.png" ],
    [ "Rockhaven Homes",        "builders/rockhaven-homes.png" ],
    [ "Schuber Mitchell Homes", "builders/schuber-mitchell-homes.avif" ],
    [ "Signature Homes",        "builders/sig-homes.svg", [ "SIG Homes" ] ]
  ].freeze

  attr_reader :name, :logo, :aliases

  def initialize(name, logo, aliases = [])
    @name    = name
    @logo    = logo
    @aliases = aliases
  end

  def self.all
    @all ||= ENTRIES.map { |name, logo, aliases| new(name, logo, aliases || []) }
  end

  def self.names
    all.map(&:name)
  end

  # Case-insensitive lookup by display name (or a prior alias). Returns nil when
  # the company doesn't match a predefined builder (e.g. legacy free-text entries).
  def self.find_by_name(name)
    return nil if name.to_s.strip.empty?

    key = name.to_s.strip.downcase
    all.find { |builder| ([ builder.name ] + builder.aliases).any? { |n| n.downcase == key } }
  end
end
