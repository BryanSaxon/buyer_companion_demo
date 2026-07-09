# Predefined list of production home builders offered on the intake form.
# Each builder maps a display name to a logo asset (served by Propshaft from
# app/assets/images). This is a static registry, not an ActiveRecord model.
class Builder
  ENTRIES = [
    [ "Classic Homes",          "builders/classic-homes.svg" ],
    [ "Eastbrook Homes",        "builders/eastbrook-homes.webp" ],
    [ "Grand Homes",            "builders/grand-homes.png" ],
    [ "Keystone Custom Homes",  "builders/keystone-homes.png" ],
    [ "Pahlisch Homes",         "builders/pahlisch-homes.png" ],
    [ "Robert Thomas Homes",    "builders/robert-thomas-homes.png" ],
    [ "Rockhaven Homes",        "builders/rockhaven-homes.png" ],
    [ "Schuber Mitchell Homes", "builders/schuber-mitchell-homes.avif" ],
    [ "SIG Homes",              "builders/sig-homes.svg" ]
  ].freeze

  attr_reader :name, :logo

  def initialize(name, logo)
    @name = name
    @logo = logo
  end

  def self.all
    @all ||= ENTRIES.map { |name, logo| new(name, logo) }
  end

  def self.names
    all.map(&:name)
  end

  # Case-insensitive lookup by display name. Returns nil when the company
  # doesn't match a predefined builder (e.g. legacy free-text entries).
  def self.find_by_name(name)
    return nil if name.to_s.strip.empty?

    key = name.to_s.strip.downcase
    all.find { |builder| builder.name.downcase == key }
  end
end
