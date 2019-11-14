
# Rails API y Arquitectura Limpia

**Repositorio:** [https://github.com/duende84/rails_api_demo](https://github.com/duende84/rails_api_demo)

**Google Doc:** [Link](https://docs.google.com/document/d/1ffKBWUnCVUsSLGdWqgXXl6fzQcBlBLmU7PRn3k3fcZA/edit?usp=sharing)

**Google Slide:** [Link](https://docs.google.com/presentation/d/1pHgunWEkqlOkQARE2lyzb9ToJ6MnmYCnVpsdZiUogWw/edit?usp=sharing)

## Antes de empezar
Instalar Ruby usando `rvm` como gestor de versiones.
- `rvm install 2.6.3`
- `rvm use 2.6.3`
- `ruby -v`

Instalar Rails
- `gem install rails`
- `rails -v`
- `Rails 6.0.1`

Para iniciar el servidor
- `rails server`

## 1. Crear el proyecto

`rails new api_demo --api --database=postgresql -T --no-rdoc --no-ri`

`--api` Configura el proyecto para que actúe como una API.

`--database=postgresql` Configura el adaptador de base de datos PostgreSQL, por defecto Rails usa SQLite.

`-T` Evita la generación e instalación de archivos de pruebas.

`--no-rdoc --no-ri` Evita descargar la documentación de las gemas/dependencias.

**Configurar la conexión a la base de datos**

En `config/database.yml`
```yml
default: &default
 ...
 username: user
 password: pass
 host: localhost
 ```

## 2. Autenticación y Autorizacion

**Incluir devise y doorkeeper en `Gemfile`**

```ruby
# Authentication
gem 'devise', '~> 4.7', '>= 4.7.1'

# Authorization
gem 'doorkeeper', '~> 5.2', '>= 5.2.1'
```
**Instalar**
- `bundle install`

**Crear la estrategia para la autenticación**

En `lib/warden_strategies.rb`
```ruby
  Warden::Strategies.add(:user_strategy) do
    def valid?
      !params[:email].blank? && !params[:password].blank?
    end

    def authenticate!
      user = User.find_for_database_authentication(email: params[:email])
      if user && user.valid_for_authentication? { user.valid_password?(params[:password]) }
        success!(user)
      else
        fail!("Could not log in")
      end
    end
  end
```

**Configurar devise**

- `rails generate devise:install`

- En `config/environments/development.rb`
  `config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }`

- Crear el modelo `Usuarios`
  `rails generate devise User`

 - En `config/initializers/devise.rb`
  ```ruby
   config.warden do |manager|
     manager.intercept_401 = false
     manager.default_strategies(scope: :user).unshift :user_strategy
   end
  ```

**Configurar doorkeeper**

- `rails generate doorkeeper:migration`
- En `config/initializers/doorkeeper.rb`
  ```ruby
    require 'warden_strategies'

    resource_owner_authenticator do
      current_user || request.env['warden'].authenticate!(:user_strategy, store: false)
    end

    # In this flow, a token is requested in exchange for the resource owner credentials (email and password)
    resource_owner_from_credentials do |routes|
      request.env['warden'].authenticate!(:user_strategy, store: false)
    end

    api_only

    access_token_expires_in nil

    grant_flows %w[password client_credentials]

    skip_authorization do
      true
    end
  ```
**Crear la base de datos en el motor**

- `rails db:create`
- `rails db:migrate`

**Configurar el enrutamiento**

En `config/routes.rb`
```ruby
  Rails.application.routes.draw do
    use_doorkeeper do
      # it accepts :authorizations, :tokens, :token_info, :applications and :authorized_applications
      skip_controllers :applications, :authorized_applications, :authorizations, :token_info
    end

    # module: The Folder
    # path: The URI
    scope module: :api, defaults: { format: :json }, path: 'api' do
      scope module: :v1, path: 'v1' do
        devise_for :users, skip: [:sessions, :password]
      end
    end
  end
```

**Validar el usuario según el token**

En `app/controllers/application_controller.rb`
```ruby
  class ApplicationController < ActionController::API
    # Doorkeeper code
    before_action :doorkeeper_authorize!
    before_action :current_resource_owner
    respond_to :json

    private

    # Doorkeeper methods
    def current_resource_owner
      if doorkeeper_token
        @current_application = doorkeeper_token.application
        resource_owner_id = doorkeeper_token.resource_owner_id
        @current_user = User.find(resource_owner_id)
      end
    end

    def current_user
      @current_user
    end

    def current_application
      @current_application
    end
  end
```
**Sobrescribir el comportamiento del `registrations_controller` de devise**

En `controllers/api/v1/registrations_controller.rb`
```ruby
  skip_before_action :doorkeeper_authorize!

  def create
    resource = build_resource(sign_up_params)
    resource.save
    if resource.persisted?
      if resource.active_for_authentication?
        # set_flash_message! :notice, :signed_up
        # To avoid login comment out sign_up method
        # sign_up(resource_name, resource)
        render json: resource # , location: after_sign_up_path_for(resource)
      else
        # set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        render json: resource # , location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
```
**Doorkeeper application**

En `db/seed.rb`
```ruby
  Doorkeeper::Application.create(
    name: "api_demo_client",
  uid: "eNKozGKHxLk_HNqRnAjbCJDCNVDazCcQtEhCOFdlNeQ",
    secret: "86j_pTRc3S_v90f43jOeZai9AQipBhJH_GGapJEo-h4",
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob")
```
`rails db:seed`

**Probemos con [HTTPie](https://httpie.org/)**

- Solicitar token de aplicación
  ```
  http POST :3000/oauth/token grant_type=client_credentials client_id=eNKozGKHxLk_HNqRnAjbCJDCNVDazCcQtEhCOFdlNeQ client_secret="86j_pTRc3S_v90f43jOeZai9AQipBhJH_GGapJEo-h4"
  ```

  Respuesta
  ```json
  {
      "access_token": "09DatReoldycpxmOdKxRfRyJYcxzsFhdOZhBk7RxbI0",
      "created_at": 1573748874,
      "token_type": "Bearer"
  }
  ```

- Registrar usuario
  ```
  http POST :3000/api/v1/users user:='{"email":"test@mail.com", "password":"123456"}'
  ```
  Respuesta
  ```json
  {
      "data": {
          "created_at": "2019-11-14T18:18:23.713Z",
          "email": "test@mail.com",
          "id": 2,
          "updated_at": "2019-11-14T18:18:23.713Z"
      }
  }
  ```

- Solicitar token de usuario - Login
  ```
  http POST :3000/oauth/token grant_type=password client_id=eNKozGKHxLk_HNqRnAjbCJDCNVDazCcQtEhCOFdlNeQ email=test@mail.com password=123456 client_secret='86j_pTRc3S_v90f43jOeZai9AQipBhJH_GGapJEo-h4'
  ```

  Respuesta
  ```json
  {
      "access_token": "NDJwP29ucPH1OlUnif1AEBXxNZhYSl4XBDK33V06ML0",
      "created_at": 1573755649,
      "token_type": "Bearer"
  }
  ```

## 2. Arquitectura: Casos de Uso

**Incluir interactor en `Gemfile`**
```ruby
  # Use cases - Clean Architecture
  gem 'interactor-rails', '~> 2.2', '>= 2.2.1'
```
**Instalar**
- `bundle install`

### 2.1. Caso de uso "Registrar Usuario"

**Crear el punto de acceso**

- `rails generate interactor:organizer sign_up_user create_user send_welcome_email track_analytic`

**Crear los interactors**

- `rails generate interactor create_user`
- En `app/interactors/create_user.rb`
  ```ruby
    def call
      user = User.new(email: context.email, password: context.password)
      if user.save && user.active_for_authentication?
        context.user = user
      else
        context.fail!(message: user.errors)
      end
    end
  ```
- `rails generate interactor send_welcome_email`
- `rails generate interactor track_analytic`

**Modificar el controlador para que use el punto de acceso**

En `app/controllers/api/v1/registrations_controller.rb`
```ruby
  def create
    result = SignUpUser.call(email: sign_up_params[:email], password: sign_up_params[:password])

    if result.success?
      render json: { data: result.user }, status: :ok
    else
      render json: { errors: result.message }, status: :unprocessable_entity
    end
  end
```

**Probemos con [HTTPie](https://httpie.org/)**

- Registrar usuario
  ```
  http POST :3000/api/v1/users user:='{"email":"test@mail.com", "password":"123"}'
  ```
  Respuesta
  ```json
  {
      "errors": {
          "email": [
              "has already been taken"
          ],
          "password": [
              "is too short (minimum is 6 characters)"
          ]
      }
  }
  ```
- Registrar usuario
  ```
  http POST :3000/api/v1/users user:='{"email":"test2@mail.com", "password":"123456"}'
  ```
  Respuesta
  ```json
  {
      "data": {
          "created_at": "2019-11-14T18:35:13.036Z",
          "email": "test2@mail.com",
          "id": 3,
          "updated_at": "2019-11-14T18:35:13.036Z"
      }
  }
  ```

### 2.2. Caso de uso "Listar transacciones por usuario"

**Crear el modelo Transacciones y su relación con Usuarios**
- `rails generate model Transaction description:string type:string amount:float user:references`

  En `app/models/transaction.rb`

  ```ruby
  class Transaction < ApplicationRecord
    belongs_to :user

    def self.types
      %w(Income Expense)
    end
  end

  class Income < Transaction; end
  class Expense < Transaction; end
  ```

- En user.rb
  ```ruby
  has_many :transactions
  ```

- Configurar el enrutamiento

  En `routes.rb`
  ```ruby
    ...
    scope module: :v1, path: 'v1' do
        ...
        resources :transactions, only: [:index]
      end
      ...
  ```

- Crear el controlador

  En `app/controllers/api/v1/transactions_controller.rb`
  ```ruby
    def index
      result = GetUserTransactions.call(user: current_user)

      if result.success?
        render json: { data: result.transactions }, status: :ok
      else
        render json: { errors: result.message }, status: :unprocessable_entity
      end
    end
  ```

**Crear el punto de acceso**
- `rails generate interactor:organizer get_user_transactions filter_transaction track_analytic`

**Crear los interactors**
- `rails generate interactor filter_transaction`
- En `app/interactors/filter_transaction.rb`
  ```ruby
    def call
      context.transactions = context.user.transactions
    end
  ```
**Actualizar la base de datos**
- `rails db:migrate`

**Crear datos de prueba**
- `rails c`
  ```ruby
    user = User.find_by_email("test@mail.com")
    user.transactions.build(description: "transaction 1", type: Income, amount: 25000).save
    Income.create(description: "transaction 2", amount: 15000, user_id: user.id)
    Transaction.create(description: "transaction 3", amount: 5000, user_id: user.id, type: Expense)
    Transaction.where(user_id: user.id)
  ```

**Probemos con [HTTPie](https://httpie.org/)**

- Listar transacciones por usuario
  ```
  http :3000/api/v1/transactions 'Authorization:Bearer NDJwP29ucPH1OlUnif1AEBXxNZhYSl4XBDK33V06ML0'
  ```
   Respuesta
  ```json
  {
      "data": [
          {
              "amount": 25000.0,
              "created_at": "2019-11-14T19:10:25.994Z",
              "description": "transaction 1",
              "id": 3,
              "updated_at": "2019-11-14T19:10:25.994Z",
              "user_id": 2
          },
          {
              "amount": 15000.0,
              "created_at": "2019-11-14T19:10:38.718Z",
              "description": "transaction 2",
              "id": 4,
              "updated_at": "2019-11-14T19:10:38.718Z",
              "user_id": 2
          },
          {
              "amount": 5000.0,
              "created_at": "2019-11-14T19:11:23.012Z",
              "description": "transaction 3",
              "id": 5,
              "updated_at": "2019-11-14T19:11:23.012Z",
              "user_id": 2
          }
      ]
  }
  ```
