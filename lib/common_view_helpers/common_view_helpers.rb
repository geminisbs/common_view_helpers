module CommonViewHelpers
  module ViewHelpers

    # Use words if within the last week, otherwise use date (show year if not this year)
    def time_ago_in_words_or_date(date,options={})
      return unless date
      if (Time.now-date)/60/60/24 < 7
        time_ago_in_words(date) + " ago"
      elsif date.year == Time.now.year
        options[:short_format] ? date.strftime(options[:short_format]) : date.strftime("%b %e").gsub("  ", " ")
      else
        options[:long_format] ? date.strftime(options[:long_format]) : date.strftime("%b %e, %Y").gsub("  ", " ")
      end
    end

    # Output an easily styleable key-value pair
    def info_pair(label, value)
      value = content_tag(:span, "None", :class => "blank") if value.blank?
      label = content_tag(:span, "#{label}:", :class => "label")
      content_tag(:span, [label, value].join(" "), :class => "info_pair")
    end

    # Give this helper an array, and get back a string of <li> elements.
    # The first item gets a class of first and the last, well.. last.
    # This makes it easier to apply CSS styles to lists, be they ordered or unordered.
    # http://zeke.tumblr.com/post/98025647/a-nice-little-view-helper-for-generating-list-items
    def convert_to_list_items(items, *args)
      default_options = {:stripe => true}
      options = default_options.merge(args.extract_options!)
      out = []
      items.each_with_index do |item, index|
        css = []
        css << "first" if items.first == item
        css << "last" if items.last == item
        css << "even" if options[:stripe] && index%2 == 1
        css << "odd" if options[:stripe] && index%2 == 0 # (First item is odd (1))
        out << content_tag(:li, item, :class => css.join(" "))
      end
      out.join("\n")
    end

    # Build an HTML table
    # For collection, pass an array of arrays
    # For headers, pass an array of label strings for the top of the table
    # All other options will be passed along to the table content_tag
    def generate_table(collection, headers=nil, options={})
      return if collection.blank?
      thead = content_tag(:thead) do
        content_tag(:tr) do
          headers.map {|header| content_tag(:th, header)}
        end
      end unless headers.nil?
      tbody = content_tag(:tbody) do
        collection.map do |values|
          content_tag(:tr) do
            values.map {|value| content_tag(:td, value)}
          end
        end
      end
      content_tag(:table, [thead, tbody].compact.join("\n"), options)
    end

    # Pass in an ActiveRecord object, get back edit and delete links inside a TD tag
    def options_td(record_or_name_or_array, hide_destroy = false)
      items = []
      items << link_to('Edit', edit_polymorphic_path(record_or_name_or_array))
      items << link_to('Delete', polymorphic_path(record_or_name_or_array), :confirm => 'Are you sure?', :method => :delete, :class => "destructive") unless hide_destroy
      list = content_tag(:ul, convert_to_list_items(items))
      content_tag(:td, list, :class => "options")
    end

    # This works just like link_to, but with one difference..
    # If the link is to the current page, a class of 'active' is added
    def link(name, options={}, html_options={})
      link_to_unless_current(name, options, html_options) do
        html_options[:class] = (html_options[:class] || "").split(" ").push("active").join(" ")
        link_to(name, options, html_options)
      end
    end

    # Absolute path to an image
    def image_url(source)
      base_url + image_path(source)
    end

    # e.g. http://localhost:3000, or https://productionserver.com
    def base_url
      "#{request.protocol}#{request.host_with_port}"
    end

    # Generate a list of column name-value pairs for an AR object
    def list_model_columns(obj)
      items = obj.class.columns.map{ |col| info_pair(col.name, obj[col.name]) }
      content_tag(:ul, convert_to_list_items(items), :class => "model_columns")
    end

    # Outputs a JS friendly (escaped) string
    def js_string(string)
      js_escape_map = {
        '\\'    => '\\\\',
        '</'    => '<\/',
        "\r\n"  => '\n',
        "\n"    => '\n',
        "\r"    => '\n',
        '"'     => '\\"',
      "'"     => "\\'" }

      string.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { js_escape_map[$1] }
    end

    # Generates a URL and automatically adds http:// if not already there
    # Useful alongside link() or when linking to user submitted addresses
    def urlify(addr)
      (addr.blank? || addr.starts_with?('http')) ? addr : "http://#{addr}"
    end

    # Breaks up a BigNum, FixNum or Float with commas
    # e.g., 532566 => 532,566 and 79593255.66 => 79,593,255.66
    def commify(num)
      num.to_s =~ /([^\.]*)(\..*)?/
      int, dec = $1.reverse, $2 ? $2 : ""
      while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3'); end
      int.reverse + dec
    end
    
    def snakeify(string)
      string.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

  end
end
