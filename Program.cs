using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using RainerBlog;
using RainerBlog.Mutation;
using RainerBlog.Query;
using RainerBlog.Utils;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<BlogDbContext>(
    options => options.UseNpgsql(
        builder.Configuration.GetConnectionString("Postgres")));

builder.Services
    .AddOpenApi()
    .AddGraphQLServer()
    .AddQueryType<BaseQuery>()
    .AddTypeExtension<UserQuery>()
    .AddMutationType<BaseMutation>()
    .AddTypeExtension<UserMutation>()
    .AddProjections()
    .AddFiltering()
    .AddSorting()
    .RegisterDbContextFactory<BlogDbContext>();


var jwtSettings = builder.Configuration.GetSection("JwtSettings");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSettings["Secret"]!))
        };
    });

builder.Services.AddAuthentication();
builder.Services.AddScoped<JwtService>();

var app = builder.Build();

app.UseHttpsRedirection();

app.UseRouting();
app.MapGraphQL();
app.UseAuthentication();
app.UseAuthorization();

app.Run();