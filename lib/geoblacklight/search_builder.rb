module Geoblacklight
  class SearchBuilder < Blacklight::Solr::SearchBuilder
    self.default_processor_chain += [:add_spatial_params]

    def initialize(processor_chain, scope)
      super(processor_chain, scope)
      @processor_chain += [:add_spatial_params] unless @processor_chain
                                                       .include?(:add_spatial_params)
    end

    def hide_child_resources(solr_params)
      return if show_action? || parent_search?
      solr_params[:fq] ||= []
      solr_params[:fq] << "!dct_isPartOf_sm:['' TO *]"
      # solr_params[:fq] ||= []
      # byebug
    end

    def self.show_actions
      [:show]
    end

    def show_action?
      self.class.show_actions.include? blacklight_params["action"].to_sym
    end

    def parent_search?
      blacklight_params["f"]["dct_isPartOf_sm"]
    end

    ##
    # Adds spatial parameters to a Solr query if :bbox is present.
    # @param [Blacklight::Solr::Request] solr_params :bbox should be in Solr
    # :bbox should be passed in using Solr lat-lon rectangle format e.g.
    # "minX minY maxX maxY"
    # @return [Blacklight::Solr::Request]
    def add_spatial_params(solr_params)
      if blacklight_params[:bbox]
        solr_params[:bq] ||= []
        solr_params[:bq] = ["#{Settings.GEOMETRY_FIELD}:\"IsWithin(#{envelope_bounds})\"^10"]
        solr_params[:fq] ||= []
        solr_params[:fq] << "#{Settings.GEOMETRY_FIELD}:\"Intersects(#{envelope_bounds})\""
      end
      solr_params
    rescue Geoblacklight::Exceptions::WrongBoundingBoxFormat
      # TODO: Potentially delete bbox params here so that its not rendered as search param
      solr_params
    end

    ##
    # @return [String]
    def envelope_bounds
      bounding_box.to_envelope
    end

    ##
    # Returns a Geoblacklight::BoundingBox built from the blacklight_params
    # @return [Geoblacklight::BoundingBox]
    def bounding_box
      Geoblacklight::BoundingBox.from_rectangle(blacklight_params[:bbox])
    end
  end
end
