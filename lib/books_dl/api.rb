module BooksDL
  class API
    attr_reader :current_cookie, :book_id, :encoded_token

    COOKIE_FILE_NAME = 'cookie.json'.freeze
    IMAGE_EXTENSIONS = %w[.bmp .gif .ico .jpeg .jpg .tiff .tif .svg .png .webp].freeze
    NO_AUTH_EXTENSIONS = %w[css].freeze

    # API ENDPOINTS
    #
    # rubocop:disable Metrics/LineLength
    CART_URL = 'https://db.books.com.tw/shopping/cart_list.php'.freeze
    LOGIN_HOST = 'https://cart.books.com.tw'.freeze
    LOGIN_PAGE_URL = "https://cart.books.com.tw/member/login?url=#{CART_URL}".freeze
    LOGIN_ENDPOINT_URL = 'https://cart.books.com.tw/member/login_do/'.freeze

    DEVICE_REG_URL = 'https://appapi-ebook.books.com.tw/V1.3/CMSAPIApp/DeviceReg'.freeze
    OAUTH_URL = 'https://appapi-ebook.books.com.tw/V1.3/CMSAPIApp/LoginURL?type=&device_id=&redirect_uri=https%3A%2F%2Fviewer-ebook.books.com.tw%2Fviewer%2Flogin.html'.freeze
    OAUTH_ENDPOINT_URL = 'https://appapi-ebook.books.com.tw/V1.3/CMSAPIApp/MemberLogin?code='.freeze
    BOOK_DL_URL = 'https://appapi-ebook.books.com.tw/V1.3/CMSAPIApp/BookDownLoadURL'.freeze
    # rubocop:enable Metrics/LineLength

    def initialize(book_id)
      @book_id = book_id
      load_existed_cookies
      @encoded_token ||= CGI.escape(info.download_token)
    end

    def fetch(path)
      url = "#{info.download_link}#{path}"
      ext = File.extname(path).downcase

      if NO_AUTH_EXTENSIONS.include?(ext)
        get(url).body.to_s
      elsif IMAGE_EXTENSIONS.include?(ext)
        checksum = Utils.img_checksum
        resp = get("#{url}?checksum=#{checksum}&DownloadToken=#{encoded_token}")

        resp.body.to_s
      else
        key = Utils.generate_key(url, info.download_token)
        resp = get("#{url}?DownloadToken=#{encoded_token}")

        Utils.decode_xor(key, resp.body.to_s)
      end
    end

    # return Struct of [:book_uni_id, :download_link, :download_token, :size, :encrypt_type]
    def info
      @info ||= begin
        login

        data = {
          form: {
            device_id: '2b2475e7-da58-4cfe-aedf-ab4e6463757b',
            language: 'zh-TW',
            os_type: 'WEB',
            os_version: default_headers[:'user-agent'],
            screen_resolution: '1680X1050',
            screen_dpi: 96,
            device_vendor: 'Google Inc.',
            device_model: 'web'
          }
        }

        headers = {
          accept: 'application/json, text/javascript, */*; q=0.01',
          'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
          Origin: 'https://viewer-ebook.books.com.tw',
          Referer: 'https://viewer-ebook.books.com.tw/viewer/epub/web/?book_uni_id=E050017049_reflowable_normal',
        }

        # remove old cookies
        current_cookie.reject! { |key| %w[CmsToken redirect_uri normal_redirect_uri DownloadToken].include?(key) }
        puts '註冊 Fake device 中...'
        post(DEVICE_REG_URL, data, headers)

        puts '透過 OAuth 取得 CmsToken...'
        resp = get(OAUTH_URL)
        login_uri = JSON.parse(resp.body.to_s).fetch('login_uri')
        code = get(login_uri).headers['Location'].split('&code=').last
        get("#{OAUTH_ENDPOINT_URL}#{code}")

        resp = get("#{BOOK_DL_URL}?book_uni_id=#{book_id}&t=#{Time.now.to_i}")
        OpenStruct.new(JSON.parse(resp.body.to_s))
      end
    end

    def login
      return if logged?

      username, password = get_account_from_stdin
      login_page = get(LOGIN_PAGE_URL).body.to_s
      captcha = get_captcha_from(login_page)

      data = { form: { captcha: captcha, login_id: username, login_pswd: password } }
      headers = {
        'Host': 'cart.books.com.tw',
        'Referer': 'https://cart.books.com.tw/member/login',
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      }

      post(LOGIN_ENDPOINT_URL, data, headers)
      return if logged?

      puts "#{'-' * 10} 登入失敗，請再試一次 #{'-' * 10}\n"
      login
    end

    def logged?
      @logged = begin
        response = get(CART_URL)

        response.status == 200
      end
    end

    private

    def load_existed_cookies
      @current_cookie = JSON.parse(File.read(COOKIE_FILE_NAME))
    rescue StandardError
      @current_cookie = {}
    end

    def get_account_from_stdin
      print('請輸入帳號：')
      username = gets.chomp
      password = STDIN.getpass('請輸入密碼:').chomp

      [username, password]
    end

    def get(url, headers = {})
      headers = build_headers({ Cookie: cookie }, headers)
      response = HTTP.headers(headers).get(url)

      if response.status >= 400
        file_name = URI(url).path.split('/').last
        raise "取得 `#{file_name}` 失敗。 Status: #{response.status}"
      end

      save_cookie(response)
      response
    end

    def post(url, data = {}, headers = {})
      headers = build_headers({ Cookie: cookie }, headers)
      response = HTTP.headers(headers).post(url, data)
      save_cookie(response)

      response
    end

    def save_cookie(response)
      cookie_jar = response.cookies
      cookie_hash = cookie_jar.map { |cookie| [cookie.name, cookie.value] }.to_h
      current_cookie.merge!(cookie_hash)

      cookie_json = JSON.pretty_generate(current_cookie)
      File.open(COOKIE_FILE_NAME, 'w') do |file|
        file.write(cookie_json)
      end
    end

    def cookie
      current_cookie.reduce('') { |cookie, (name, value)| cookie + "#{name}=#{value}; " }.strip
    end

    def default_headers
      @default_headers ||= {
        'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) ' \
                      'AppleWebKit/537.36 (KHTML, like Gecko) ' \
                      'Chrome/71.0.3578.98 Safari/537.36'
      }
    end

    def build_headers(*args)
      args.reduce(default_headers, &:merge)
    end

    def get_user_input(label)
      puts label

      gets.chomp
    end

    def get_captcha_from(login_page)
      doc = Nokogiri::HTML(login_page)
      captcha_img_path = doc.at_css('#captcha_img > img').attr('src')
      captcha_img_url = "#{LOGIN_HOST}#{captcha_img_path}"

      img = get(captcha_img_url).body
      File.open('captcha.png', 'w').write(img)
      begin
        `open ./captcha.png`
      rescue StandardError
        puts '開啟失敗，請自行查看 captcha.png 檔案。'
      end
      puts '請輸入認證碼 (captcha.png，不分大小寫)：'

      gets.chomp
    end
  end
end