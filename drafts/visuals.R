library(ggplot2)

r <- robis::occurrence("Lytechinus variegatus")

r <- sf::st_as_sf(r, coords = c("decimalLongitude", "decimalLatitude"), crs = "EPSG:4326")

wrld <- rnaturalearth::ne_countries(returnclass = "sf")

ggplot() +
    geom_sf(data = wrld, fill = "grey80", color = "grey80") +
    geom_sf(data = r, color = "#004aad", size = 0.5) +
    theme_light() +
    theme(axis.text = element_blank(), panel.border = element_blank()) +
    scale_x_continuous(expand = c(0,0)) + scale_y_continuous(expand = c(0,0)) #+
    coord_sf(crs = "ESRI:54009")
ggsave("teste.png", units = "px", width = 972, height = 490)


new_recs <- data.frame(
    year = min(r$date_year,na.rm = T):max(r$date_year, na.rm = T),
    records = NA
)

for (i in seq_len(nrow(new_recs))) {
    new_recs$records[i] <- nrow(r |> filter(date_year <= new_recs$year[i]))
}


ggplot() +
    geom_line(data = new_recs, aes(x = year, y = records), color = "#004aad") +
    theme_light() +
    ylab("Records") + xlab(NULL) +
    theme(panel.border = element_blank())


r$h3 <- h3jsr::point_to_cell(r, res = 5)

new_recs <- data.frame(
    year = min(r$date_year,na.rm = T):max(r$date_year, na.rm = T),
    new_cells = NA
)

for (i in seq_len(nrow(new_recs))) {
    new_recs$records[i] <- r |> filter(date_year <= new_recs$year[i]) |> group_by(h3) |> count() |> nrow()
}


ggplot() +
    geom_line(data = new_recs, aes(x = year, y = records), color = "#004aad") +
    theme_light() +
    ylab("Unique cells") + xlab(NULL) +
    theme(panel.border = element_blank())


sst_d <- r |> select(sst) |> sf::st_drop_geometry() |> filter(!is.na(sst))
# sst_d$integers <- as.integer(sst_d$sst)

# sst_d <- sst_d |> group_by(integers) |> count() |> filter(!is.na(integers))
sst_d$group <- "a"
library(ggdist)
ggplot(data = sst_d) +
    stat_halfeye(aes(x = sst, y = 1)) +
    # geom_jitter(aes(x = sst, y = "a"), height = 0.02, alpha = .3) +
    # stat_pointinterval(aes(x = sst, y = "a")) +
    theme_light() #+
    #scale_y_continuous(limits = c(0.94, 1.05), expand = c(0,0))
ggsave("teste2.png", height = 4, width = 8)

ggplot(data = sst_d) +
  geom_jitter(
    aes(x = sst, y = factor("a")),
    color = "#004aad",
    height = 0.11,
    alpha = 0.5
  ) +
  stat_pointinterval(
    aes(x = sst, y = factor("a")),
    position = position_nudge(y = 0.2), color = "#004aad"
  ) +
  theme_light() +
  labs(y = NULL) +
  scale_y_discrete(expand = c(0,0)) +
  theme(panel.border = element_blank(), panel.grid.major.y = element_blank(),
  axis.text.y = element_blank(), legend.position = "none", axis.title.y = element_blank(),
  plot.margin = unit(c(0,0,0,0), "mm"))
ggsave("teste2.png", height = 2, width = 10)


sst_d_b <- sst_d |> summarise(max = max(sst), min = min(sst), median = median(sst))

sst_d_b <- data.frame(value = c(29, 12.3, 25.4))

ggplot() +
  geom_point(sst_d_b) +
  theme_light() +
  labs(y = NULL) +
  scale_y_discrete(expand = c(0,0)) +
  theme(panel.border = element_blank(), panel.grid.major.y = element_blank(),
  axis.text.y = element_blank(), legend.position = "none", axis.title.y = element_blank(),
  plot.margin = unit(c(0,0,0,0), "mm"))
ggsave("teste2.png", height = 2, width = 10)



ggplot(data = sst_d) +
  geom_jitter(
    aes(x = sst, y = factor("a")),
    color = "#a4a4a4",
    height = 0.005,
    alpha = 0.1
  ) +
  geom_linerange(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.05), quantile(sst_d$sst, 0.95))),
    aes(xmin = min(sst_lims),xmax = max(sst_lims), y = factor("a")),
    linewidth = 1,color = "#004aad"
  ) +
  geom_point(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.05), quantile(sst_d$sst, 0.95))),
    aes(x = sst_lims, y = factor("a")),
    size = 4, color = "#004aad"
  ) +
  geom_point(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.5))),
    aes(x = sst_lims, y = factor("a")), shape = 15,
    size = 4, color = "#004aad"
  ) +
#   geom_point(
#     data = data.frame(sst_lims = median(sst_d$sst)),
#     aes(x = sst_lims, y = factor("a")),
#     size = 14, shape = "|", color = "#000000"
#   ) +
geom_text(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.05), quantile(sst_d$sst, 0.5), quantile(sst_d$sst, 0.95))),
    aes(x = sst_lims, y = factor("a"), label =round(sst_lims,1)),
    size = 5, color = "#004aad", position = position_nudge(y = 0.01)
  ) +
  theme_light() +
  labs(y = NULL) +
  scale_y_discrete(expand = c(0.01,0.01)) +
  theme(panel.border = element_blank(), panel.grid.major.y = element_blank(),
  axis.text.y = element_blank(), legend.position = "none", axis.title.y = element_blank(),
  plot.margin = unit(c(0,0,0,0), "mm"))
ggsave("teste2.png", height = 1.5, width = 7.5)





ggplot(data = sst_d) +
  geom_jitter(
    aes(x = sst, y = factor("a")),
    color = "#606060",
    height = 0.01,
    alpha = 0.1
  ) +
  stat_pointinterval(
    aes(x = sst, y = factor("a")), color = "#004aad",
    size = 8
  ) +
#   geom_point(
#     data = data.frame(sst_lims = median(sst_d$sst)),
#     aes(x = sst_lims, y = factor("a")),
#     size = 14, shape = "|", color = "#000000"
#   ) +
# geom_text(
#     data = data.frame(sst_lims = c(min(sst_d$sst), max(sst_d$sst))),
#     aes(x = sst_lims, y = factor("a"), label =round(sst_lims,1)),
#     size = 5, color = "#004aad", position = position_nudge(y = 0.01)
#   ) +
  theme_light() +
  labs(y = NULL) +
  scale_y_discrete(expand = c(0.01,0.01)) +
  theme(panel.border = element_blank(), panel.grid.major.y = element_blank(),
  axis.text.y = element_blank(), legend.position = "none", axis.title.y = element_blank(),
  plot.margin = unit(c(0,0,0,0), "mm"))
ggsave("teste2.png", height = 2, width = 10)



ggplot(data = sst_d) +
 stat_halfeye(aes(x = sst, y = "a"), color = "#004aad", fill = "#d6d6d6") +
  theme_light() +
  labs(y = NULL) +
  scale_y_discrete(expand = c(0.05,0.01)) +
  theme(panel.border = element_blank(), panel.grid.major.y = element_blank(),
  axis.text.y = element_blank(), legend.position = "none", axis.title.y = element_blank())
ggsave("teste2.png", height = 1.5, width = 6)


ggplot(data = sst_d) +
 geom_histogram(aes(x = sst), fill = "#004aad", color = "white", linewidth = 0.1) +
 geom_linerange(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.05), quantile(sst_d$sst, 0.95))),
    aes(xmin = min(sst_lims),xmax = max(sst_lims), y = 0),
    linewidth = 1,color = "#bbbbbb", position = position_nudge(y = -9)
  ) +
  geom_point(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.05), quantile(sst_d$sst, 0.95))),
    aes(x = sst_lims, y = 0),
    size = 2, color = "#004aad", position = position_nudge(y = -9)
  ) +
  geom_point(
    data = data.frame(sst_lims = c(quantile(sst_d$sst, 0.5))),
    aes(x = sst_lims, y = 0), shape = 21,
    size = 2, color = "#004aad", fill = "white", position = position_nudge(y = -9)
  ) +
  theme_light() +
  labs(y = NULL) +
 # scale_y_discrete(expand = c(0.05,0.01)) +
  theme(panel.border = element_blank(), panel.grid.major.y = element_blank(),
  panel.grid.minor.y = element_blank(),
  axis.text.y = element_blank(), legend.position = "none", axis.title.y = element_blank(),
  axis.ticks.y = element_blank())
ggsave("teste2.png", height = 2, width = 6)
