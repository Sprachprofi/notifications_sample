# Core extensions
Dir[File.join(Rails.root, 'lib', 'core_ext', '*.rb')].each { |l| require l }

# Notifiers
Dir[File.join(Rails.root, 'lib', 'notifiers', '*.rb')].each { |l| require l }

