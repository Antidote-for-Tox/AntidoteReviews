#!/usr/bin/env ruby

require "spaceship"
require "fileutils"
require "yaml"

def format_review(review, add_language)
    result = "###" + review["title"]
    result += "\n\n"

    rating = review["rating"]
    for i in 1..5
        if i <= rating
            result += "★"
        else
            result += "☆"
        end
    end

    time = Time.at(review["created"] / 1000)

    result += " " + review["nickname"] + ", " + time.to_date.to_s

    if add_language
        result += ", **" + review["storeFront"] + "**"
    end

    result += "\n\n"

    result += "```\n"
    result += review["review"]
    result += "\n```"
    result += "\n\n"

    return result
end

def format_all(reviews, add_language = false)
    sorted = reviews.sort { |x,y| y["created"] <=> x["created"] }
    result = ""

    for r in sorted
        result += format_review(r, add_language)
    end

    return result
end

def format_average(ratings, language)
    if language
        summary = ratings.store_fronts[language]
    else
        summary = ratings.rating_summary
    end

    result = "##Average stars: " + summary.average_rating.to_s + "/5.0"
    result += "\n\n"
    result += "- ★★★★★ - " + summary.five_star_rating_count.to_s + "\n"
    result += "- ★★★★☆ - " + summary.four_star_rating_count.to_s + "\n"
    result += "- ★★★☆☆ - " + summary.three_star_rating_count.to_s + "\n"
    result += "- ★★☆☆☆ - " + summary.two_star_rating_count.to_s + "\n"
    result += "- ★☆☆☆☆ - " + summary.one_star_rating_count.to_s + "\n"
    result += "\n---\n\n"

    return result
end

puts "Log in..."
Spaceship::Tunes.login

ratings = Spaceship::Tunes::Application.find("me.dvor.Antidote").ratings


folder = "reviews"
FileUtils::mkdir_p folder

all = []

for key in ratings.store_fronts.keys
    language = key.downcase
    puts "Getting reviews for language " + language + "..."

    file_path = folder + "/" + language + ".md"

    reviews = ratings.reviews(language)
    all += reviews

    result = format_average(ratings, key)
    result += format_all(reviews)

    File.write(file_path, result)
end

puts "Saving reviews for all languages..."

all_result = format_average(ratings, nil)
all_result += format_all(all, true)
all_path = folder + "/all.md"

File.write(all_path, all_result)
