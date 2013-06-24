class ResultController < ApplicationController
  def search
    @query = params[:query_term].nil? ? 1 : params[:query_term]
    p @query
  end
end
