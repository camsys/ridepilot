# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( google_map.js styledmarker.js jquery.jstree.js jquery.layout.js dispatcher.js jstree-apple/* jquery-layout-default.css *.png v1_theme.css v1_theme_split2.css reports_print.css ) 