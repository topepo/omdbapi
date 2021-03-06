#' Retrieve OMDB info by title search
#'
#' @md
#' @param title Movie title to search for.
#' @param type Type of result to return. One of `[movie|series|episode|game]`.
#' @param year_of_release Year of release.
#' @param season if `type` is \code{series} or \code{episode} then it possible
#'        to search within a \code{season} AND \code{epispde} (both required)
#' @param episode if \code{type} is \code{series} or \code{episode} then it possible
#'        to search within a \code{season} AND \code{epispde} (both required)
#' @param plot Return \code{short} or \code{full} plot.
#' @param include_tomatoes Include Rotten Tomatoes ratings.
#' @param api_key OMDB API key. See [omdb_api_key()] & <https://www.patreon.com/bePatron?u=5038490> for more information.
#' @seealso \href{omdbAPI documentation}{http://www.omdbapi.com/}
#' @return \code{tbl_df}/\code{data.frame} of search results (an empty one if none found). Also
#'         classes as an \code{omdb} object for prettier printing
#' @note The API's search results limit to 10.
#' @export
find_by_title <- function(title, type=NULL, season=NULL, episode=NULL,
                          year_of_release=NULL, plot="short", include_tomatoes=FALSE,
                          api_key=omdb_api_key()) {

  if (!is.null(type)) {
    if (!type %in% c("movie", "series", "episode", "game")) {
      message('"type" must be one of "movie", "series", "episode" or "game"')
      return(data_frame())
    }
  }

  params <- list(t=title, type=type, y=year_of_release,
                 plot=plot, r="json", tomatoes=include_tomatoes, apikey=api_key)

  if (!is.null(season) & is.null(episode) |
      !is.null(episode) & is.null(season)) {
    message('Both "season" and "episode" must be specified if one is."')
    return(data_frame())
  } else {
    params["Season"] <- season
    params["Episode"] <- episode
  }

  resp <- httr::GET(OMDB_BASE_URL, query=params)
  httr::stop_for_status(resp)
  tmp <- httr::content(resp, as="parsed")

  if (tmp$Response == "False") {
    message(tmp$Error)
    return(data_frame())
  }

  ret <- dplyr::as_data_frame(tmp)
  tmp[ tmp == "N/A" ] <- NA
  class(ret) <- c("omdb", class(ret))

  suppressWarnings(fix_omdb(ret))

}

#' Retrieve OMDB info by IMDB ID search
#'
#' @md
#' @param id A valid IMDb ID (e.g. \code{tt1285016})
#' @param type Type of result to return. One of \code{[movie|series|episode|game]}.
#' @param year_of_release Year of release.
#' @param plot Return \code{short} or \code{full} plot.
#' @param include_tomatoes Include Rotten Tomatoes ratings.
#' @param api_key OMDB API key. See [omdb_api_key()] & <https://www.patreon.com/bePatron?u=5038490> for more information.
#' @seealso \href{omdbAPI documentation}{http://www.omdbapi.com/}
#' @return \code{tbl_df}/\code{data.frame} of search results (an empty one if none found). Also
#'         classes as an \code{omdb} object for prettier printing
#' @note The API's search results limit to 10.
#' @export
find_by_id <- function(id, type=NULL, year_of_release=NULL,
                          plot="short", include_tomatoes=FALSE,
                          api_key=omdb_api_key()) {


  params <- list(i=id, type=type, y=year_of_release,
                 plot=plot, r="json", tomatoes=include_tomatoes, apikey=api_key)
  resp <- httr::GET(OMDB_BASE_URL, query=params)
  httr::stop_for_status(resp)
  tmp <- httr::content(resp, as="parsed")

  if (tmp$Response == "False") {
    message(tmp$Error)
    return(data_frame())
  }

  ret <- dplyr::as_data_frame(tmp)
  tmp[ tmp == "N/A" ] <- NA
  class(ret) <- c("omdb", class(ret))

  suppressWarnings(fix_omdb(ret))

}

#' Lightweight omdb title search
#'
#' @md
#' @param term Movie title to search for.
#' @param type Type of result to return. One of \code{[movie|series|episode|game]}.
#' @param year_of_release Year of release.
#' @param page 1 for first 10 results, 2 for next ten, etc...
#' @param api_key OMDB API key. See [omdb_api_key()] & <https://www.patreon.com/bePatron?u=5038490> for more information.
#' @seealso \href{omdbAPI documentation}{http://www.omdbapi.com/}
#' @return \code{tbl_df}/\code{data.frame} of search results (an empty one if none found)
#' @note The API's search results limit to 10 at a time (see argument page).
#' @export
search_by_title <- function(term, type=NULL, year_of_release=NULL, page = 1,
                          api_key=omdb_api_key()) {

  params <- list(s=term, type=type, y=year_of_release, page = page, r="json", apikey=api_key)
  resp <- httr::GET(OMDB_BASE_URL, query=params)
  httr::stop_for_status(resp)
  tmp <- httr::content(resp, as="parsed")

  if (!("Search" %in% names(tmp))) {
    message(tmp$Error)
    return(data_frame())
  }

  dplyr::bind_rows(lapply(tmp$Search, as.data.frame, stringsAsFactors=FALSE))

}

# Print an omdb result
#
# If either \code{find_} function finds an omdb entry, the API only returns
# a single record. That makes it possible to make a nice \code{print} routine
# for it so the output is easier to read in interactive mode.
#
# @param x omdb object
# @param \dots ignored
# @method print omdb
# @export
print.omdb <- function(x, ...) {

  x <- as.data.frame(x, stringsAsFactors=FALSE)

  cols <- setdiff(colnames(x[,which(!is.na(x[,colnames(x)]))]), "Response")

  # all possible API returns

  all_cols <- c("Title", "Year", "Rated", "Released", "Runtime", "Genre", "Director",
                "Writer", "Actors", "Plot", "Language", "Country", "Awards",
                "Poster", "Ratings", "Metascore", "imdbRating", "imdbVotes",
                "imdbID", "Type", "tomatoMeter", "tomatoImage", "tomatoRating",
                "tomatoReviews", "tomatoFresh", "tomatoRotten", "tomatoConsensus",
                "tomatoUserMeter", "tomatoUserRating", "tomatoUserReviews", "tomatoURL",
                "DVD", "BoxOffice", "Production", "Website", "Response")

  all_cols <- c("Title", "Year", "Rated", "Released", "Runtime", "Genre", "Director",
                "Writer", "Actors", "Plot", "Language", "Country", "Awards",
                "Poster", "Metascore", "imdbRating", "imdbVotes", "imdbID", "Type",
                "tomatoMeter", "tomatoImage", "tomatoRating", "tomatoReviews",
                "tomatoFresh", "tomatoRotten", "tomatoConsensus", "tomatoUserMeter",
                "tomatoUserRating", "tomatoUserReviews", "DVD", "BoxOffice",
                "Production", "Website")

  for(col in all_cols) {

    if (col %in% cols) {

      cat(str_pad(sprintf("%s: ", col), 2+max(nchar(cols))))

      if (col %in% c("Released", "DVD")) {
        cat(paste(str_wrap(format(x[,col], "%Y-%m-%d"),
                           width=options("width")$width-10,
                           exdent=nchar(str_pad(sprintf("%s: ", col), 2+max(nchar(cols))))),
                  collapse="\n"))

      } else {
        cat(paste(str_wrap(x[,col],
                           width=options("width")$width-10,
                           exdent=nchar(str_pad(sprintf("%s: ", col), 2+max(nchar(cols))))),
                  collapse="\n"))
      }

      cat("\n")

    }

  }

}
