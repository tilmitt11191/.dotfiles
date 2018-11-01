require 'yaml'

# Smart device spec data
# @abstract Get smart device spec data from User-Agent 
module SmartDeviceSpec

  SMART_DEVICE_SPEC_LIST = YAML.load_file( File.join( [File.dirname(__FILE__), 'smart_device_spec_list.yml'] ) )

  # Get smart device spec data from User-Agent and smart device spec list
  # @param [String] user_agent User-Agent
  # @return [Hash] Return smart device spec data
  def get_smart_device_spec(user_agent)
    if user_agent
      SMART_DEVICE_SPEC_LIST[:smart_device_info_tables].each do |hardware_model, smart_device_spec|
        return smart_device_spec  if user_agent.include?(hardware_model)
      end
    end
    return { :maker => nil,
             :model_name => nil,
             :carrier => nil,
             :display_class => nil,
             :os => search_os( user_agent ),
             :cellular_network => []
             }
  end

  # Check OS of smart device from User-Agent
  # @param [String] user_agent User-Agent
  # @return [String] OS name
  # @return [nil] Return nil when User-Agent does exist , or when OS name is not able to be looked for from OS list
  def search_os( user_agent )
    return nil unless user_agent
    SMART_DEVICE_SPEC_LIST[:os_list].each do |id, os|
      return os[:name] if user_agent.include?( id )
    end
    return nil
  end
  private :search_os

end