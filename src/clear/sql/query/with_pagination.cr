module Clear::SQL::Query::WithPagination
  DEFAULT_LIMIT = 50
  DEFAULT_PAGE = 1
  
  macro included
    property total_entries : Int64? = nil  
  end

  # Maybe this goes on the Collection?
  def paginate(page : Int32 = DEFAULT_PAGE, per_page : Int32 = DEFAULT_LIMIT)
    # Need to clear these values to get total count first
    clear_limit.clear_offset
    @total_entries = count
    
    # Calculate proper offset and set limit
    page = page < 1 ? 1 : page
    @limit = per_page.to_i64
    @offset = (per_page * (page - 1)).to_i64
    change!
  end

  def per_page
    limit
  end

  def current_page
    if offset.nil? || limit.nil?
      1
    else
      (offset.as(Int64) / limit.as(Int64)) + 1
    end
  end
 
  def total_pages
    if limit.nil? || total_entries.nil?
      1
    else
      (total_entries.as(Int64) / limit.as(Int64).to_f).ceil.to_i
    end
  end

  # current_page - 1 or nil if there is no previous page
  def previous_page
    current_page > 1 ? (current_page - 1) : nil
  end

  # current_page + 1 or nil if there is no next page
  def next_page
    current_page < total_pages ? (current_page + 1) : nil
  end

  # Helper method that is true when someone tries to fetch a page with a
  # larger number than the last page. Can be used in combination with flashes
  # and redirecting.
  def out_of_bounds?
    current_page > total_pages
  end
end
