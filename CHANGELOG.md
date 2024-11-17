# Changelog

## v0.2.5

### Improvements

* Was previously loading all associations, which caused timeouts for records with large amounts of associated records.
* Tests are now run on PRs instead of only pushes against main.

## v0.2.4

### Improvements

* Correct the `Dumper.Config` callback specs.

## v0.2.3

### Improvements

* Allow override of the auto-discovery of the `otp_app`.

## v0.2.2

### Improvements

* Updated the package description to reflect that it is now a LiveDashboard page and not a mix generator.

## v0.2.1

### Improvements

* Search for a record by id
* Use router config instead of app config
* Update links to use `<.link navigate={}>` instead of firing events

## v0.2.0

### Improvements

* Changed from mix task to a LiveDashboard plugin

## v0.1.1

### Improvements

* Fix phoenix heex warning where name attribute was set to "id".  Renamed to "search_id".

## v0.1.0

### Improvements

* Initial release of Dumper
