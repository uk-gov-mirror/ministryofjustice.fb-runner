class ServiceMetadataNotFoundError < StandardError
end

if File.exist?(Rails.root.join('spec', 'fixtures', 'service.json'))
  Rails.configuration.service_metadata = JSON.parse(
    File.read(Rails.root.join('spec', 'fixtures', 'service.json'))
  )

  MetadataPresenter::Schema.new(Rails.configuration.service_metadata).validate

  Rails.configuration.service = MetadataPresenter::Service.new(
    Rails.configuration.service_metadata
  )
else
  raise ServiceMetadataNotFoundError.new('No service metadata found')
end
