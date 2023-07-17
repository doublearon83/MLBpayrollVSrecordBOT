#required packages
require(mlbplotR)
require(ggplot2)
require(tidyverse)
require(rtweet)

#team abbreviations and logos from mlbplotR
team_abbr <- valid_team_names()
# remove conference logos from this example
team_abbr <- team_abbr[!team_abbr %in% c("NL", "AL", "MLB")]

#scrape payroll data
require(rvest)
payweb <- read_html("https://www.spotrac.com/mlb/payroll/")
payroll<-payweb %>%
  html_nodes(".center") %>%
  html_text()
team_p <- payweb %>%
  html_nodes(".xs-visible") %>%
  html_text()
av <- payweb %>%
  html_nodes("#averagepayroll div") %>%
  html_text()

#remove average payroll value from dataset
payroll <- payroll[-((which(payroll==av)-7):which(payroll==av))]
payroll <- payroll[seq(grep("Total Payroll",payroll),length(payroll),grep("Total Payroll",payroll))]
payroll <- payroll[-1]

#payroll data
payroll <- data.frame(team_p,payroll)
payroll$team_p[payroll$team_p=="ARI"] <- "AZ"
payroll$team_p[payroll$team_p=="CHW"] <- "CWS"
names(payroll)[1] <- "Abbr"

#scrape team records
recweb <- read_html("https://www.espn.com/mlb/standings/_/group/overall")
rec<-recweb %>%
  html_nodes(".stat-cell") %>%
  html_text()
team<-recweb %>%
  html_nodes(".AnchorLink") %>%
  html_text()

#get just win percentage
rec <- rec[seq(3,length(rec),11)]


#team abbr for record
team[team=="ARI"] <- "AZ"
team[team=="CHW"] <- "CWS"
team_nam <- team[team %in% team_abbr]

#record data
record <- data.frame(team_nam,rec)
names(record)[1] <- "Abbr"

#join record and payroll and do some tidying
rp <- full_join(record,payroll,by = "Abbr")
names(rp)[2] <- "PCT"
names(rp)[3] <- "Payroll"
rp$Payroll <- gsub(",","",rp$Payroll)
rp$Payroll <- gsub("\\$","",rp$Payroll)
rp$Payroll <- as.numeric(rp$Payroll)
rp$PCT <- as.numeric(rp$PCT)

#linear relationship between payroll and win percentage
out <- lm(PCT ~ Payroll,data=rp)
summary(out)

#difference between predicted in percentage from payroll and observed win percentage
rp$diff <- rp$PCT - predict(out)

#settings for plot
# keep alpha == 1 for all teams abs diff >0.1
matches <- grepl("A", team_abbr)
rp$alpha <- ifelse((rp$diff==max(rp$diff) | rp$diff==min(rp$diff)), 1, 0.2)
# also set a custom fill colour
rp$colour <- ifelse(abs(rp$diff)>0.1, NA, "gray")

#make plot
tt <- paste("MLB Win Percentage Versus Payroll through",format(Sys.time(),"%Y-%m-%d"),sep=" ")
ggplot(rp, aes(x=Payroll,y=PCT)) +
  #geom_point() + 
  geom_smooth(method = "lm", se=FALSE, size=1) +
  geom_mlb_logos(aes(team_abbr = Abbr, alpha = alpha), width = 0.075) +
  #geom_label(aes(label = Abbr), nudge_y = -0.35, alpha = 0.5) +
  scale_alpha_identity() +
  scale_colour_identity() +
  ylab("") +
  xlab("") +
  labs(title = tt, 
       subtitle = "Most over-performing and under-performing teams are highlighted",
       caption = "Data from ESPN and Spotrac")+
  theme_bw()
  
#save image to post on twitter
ggsave("data_for_tweet.png")


#authentication, etc.
#with Twitter API v2 you need to use client (idk why)
client <- rtweet_client(client_id = "MLB_APP_CLIENT_ID",
              client_secret = "MLB_APP_CLIENT_SECRET",
  app = "MLBpayrollVSrecordBOT"
)

#have to re-authorize every two hours with Oauth2 every 2 hours
user_oauth2 <- rtweet_oauth2(client)

#authentication that may or may not be needed with v2
#needed with post_tweet (v1), but not tweet_post (v2)
auth <- rtweet_bot(api_key = "MLB_APP_API_KEY",
                   api_secret = "MLB_APP_API_SECRET",
                   access_token = "MLB_APP_ACCESS_TOKEN",
                   access_secret = "MLB_APP_ACCESS_SECRET")

auth_as(auth)

#post tweet
#currently can only post text.
#package author is working on way to fix.
#https://stackoverflow.com/questions/76560132/using-the-new-tweet-post-in-rtweet-but-with-media
#https://github.com/ropensci/rtweet/issues/778
text_post1 <- paste("As of",format(Sys.time(),"%Y-%m-%d"),sep= " ")
text_post2 <- paste(text_post1,"the team most overperforming payroll is",sep= " ")
text_post3 <- paste(text_post2, rp$Abbr[1], sep = " ")
text_post4 <- paste(text_post3, "and the team most underperforming is", sep= " ")
text_post <- paste(text_post4, rp$Abbr[30], sep= " ")
tweet_post(text=text_post,token = user_oauth2)

#post tweet does not work with new Twitter API
post_tweet(status="MLB Record vs. Payroll",media="data_for_tweet.png",
           media_alt_text = "Relationship between MLB team record and payroll",
           token = auth)
