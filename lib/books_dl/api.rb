module BooksDL
  class API
    attr_reader :current_cookie

    COOKIE_FILE_NAME = 'cookie.json'.freeze
    LOGIN_HOST = 'https://cart.books.com.tw'.freeze
    CART_URL = 'https://db.books.com.tw/shopping/cart_list.php'.freeze
    LOGIN_PAGE_URL = "#{LOGIN_HOST}/member/login?url=#{CART_URL}".freeze
    LOGIN_ENDPOINT_URL = "#{LOGIN_HOST}/member/login_do/".freeze

    def initialize
      load_existed_cookies
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
      response = get(CART_URL)

      response.status == 200
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

    def debug(*args)
      puts '=' * 50
      args.each(&method(:ap))
      puts '=' * 50
    end
  end
end