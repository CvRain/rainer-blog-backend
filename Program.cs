using Microsoft.EntityFrameworkCore;
using RainerBlog.Mutation;
using RainerBlog.Query;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<BlogDbContext>(
    options => options.UseNpgsql(
        builder.Configuration.GetConnectionString("Postgres")));

builder.Services
    .AddOpenApi()
    .AddGraphQLServer()
    .AddQueryType<BaseQuery>()
    .AddMutationType<BaseMutation>()
    .AddProjections()
    .AddFiltering()
    .AddSorting()
    .RegisterDbContextFactory<BlogDbContext>();


var app = builder.Build();

app.UseHttpsRedirection();

app.UseRouting();
app.MapGraphQL();

app.Run();