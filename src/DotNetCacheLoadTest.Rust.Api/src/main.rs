use actix_web::{web, App, HttpServer, Responder, HttpResponse};
use redis::AsyncCommands;
use std::env;

async fn get_redis_value(key: web::Path<String>, redis_client: web::Data<redis::Client>) -> impl Responder {
    let key_str = key.clone(); // Clone the key to use it later
    let mut con = redis_client.get_async_connection().await.unwrap();
    let value: Option<String> = con.get(&key.into_inner()).await.unwrap();
    match value {
        Some(val) => {
            HttpResponse::Ok().body(val)
        },
        None => {
            println!("Key not found: {}", key_str.as_str()); // Use the cloned key
            HttpResponse::NotFound().finish()
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Get Redis connection string from environment variable
    let redis_connection_string = env::var("REDIS_CONNECTION").unwrap_or_else(|_| "redis://localhost:6379".to_string());
    println!("{}", redis_connection_string);

    // Create Redis client
    let redis_client = redis::Client::open(redis_connection_string).unwrap();

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(redis_client.clone()))
            .route("/redis/{key}", web::get().to(get_redis_value))
    })
    .bind("0.0.0.0:8080")? // Bind to 0.0.0.0 for Docker
    .run()
    .await
}
