require 'pathname'
require 'inifile'
require 'map'

module Wavefront
  # Helper methods to get Wavefront credentials.
  #
  # @return [Wavefront::Credentials]
  #
  # @!attribute config [r]
  #   @return [Map] the entire loaded config
  # @!attribute creds [r]
  #   @return [Map] credentials for speaking to the Wavefront API
  # @!attribute proxy [r]
  #   @return [Map] information for speaking to a Wavefront proxy
  #
  class Credentials
    attr_reader :opts, :config, :creds, :proxy, :all

    # Gives you an object of credentials and options for speaking to
    # Wavefront. It will look in the following places:
    #
    # ~/.wavefront
    # /etc/wavefront/credentials
    # WAVEFRONT_ENDPOINT and WAVEFRONT_TOKEN environment variables
    #
    # @param options [Hash] keys may be 'file', which
    #   specifies a config file which will be loaded and parsed. If
    #   no file is supplied, those listed above will be used.;
    #   and/or 'profile' which select a profile section from 'file'
    #
    def initialize(options = {})
      raw = load_from_file(cred_files(options), options[:profile] ||
                           'default')
      populate(env_override(raw))
    end

    # If the user has set certain environment variables, their
    # values will override values from the config file or
    # command-line.
    # @param raw [Hash] the existing credentials
    # @return [Hash] the modified credentials
    #
    def env_override(raw)
      { endpoint: 'WAVEFRONT_ENDPOINT',
        token:    'WAVEFRONT_TOKEN',
        proxy:    'WAVEFRONT_PROXY' }.each { |k, v| raw[k] = ENV[v] if ENV[v] }
      raw
    end

    # Make the helper values. We use a Map so they're super-easy to
    # access
    #
    # @param raw [Hash] the combined options from config file,
    #   command-line and env vars.
    # @return void
    #
    def populate(raw)
      @config = Map(raw)
      @creds  = Map(raw.select { |k, _v| %i[endpoint token].include?(k) })
      @proxy  = Map(raw.select { |k, _v| %i[proxy port].include?(k) })
      @all    = Map(raw.select do |k, _v|
        %i[proxy port endpoint token].include?(k)
      end)
    end

    # @return [Array] a list of possible credential files
    #
    def cred_files(opts = {})
      if opts.key?(:file)
        Array(Pathname.new(opts[:file]))
      else
        [Pathname.new('/etc/wavefront/credentials'),
         Pathname.new(ENV['HOME']) + '.wavefront']
      end
    end

    # @param files [Array][Pathname] a list of ini-style config files
    # @param profile [String] a profile name
    # @return [Hash] the given profile from the given list of files.
    #   If multiple files match, the last one will be used
    #
    def load_from_file(files, profile = 'default')
      ret = {}

      files.each do |f|
        next unless f.exist?
        ret = load_profile(f, profile)
        ret[:file] = f
      end

      ret
    end

    # Load in an (optionally) given section of an ini-style
    # configuration file not there, we don't consider that an error.
    #
    # @param file [Pathname] the file to read
    # @param profile [String] the section in the config to read
    # @return [Hash] options loaded from file. Each key becomes a
    #   symbol
    #
    def load_profile(file, profile = 'default')
      IniFile.load(file)[profile].each_with_object({}) do |(k, v), memo|
        memo[k.to_sym] = v
      end
    end
  end
end
